local Players = game:GetService("Players")
local Motion = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Motion)
local Punch = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Punch)
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Pose = {}
Pose.__index = Pose
local function release(actor)
	for motor, cf in actor.motors do
		if motor.Parent then motor.C0, motor.Transform = cf, actor.transforms[motor] end
	end
	if actor.animate and actor.animate.Parent then actor.animate.Enabled = actor.wasEnabled end
end
local function bind(character)
	local actor = {character = character, motors = {}, transforms = {}, offsets = {}, joints = {}, punchC0 = {}}
	actor.animate = character:FindFirstChild("Animate")
	if actor.animate and actor.animate:IsA("LocalScript") then actor.wasEnabled = actor.animate.Enabled; actor.animate.Enabled = false
	else actor.animate = nil end
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			actor.motors[motor], actor.transforms[motor], actor.offsets[motor] = motor.C0, motor.Transform, CFrame.new()
			actor.joints[motor.Name] = motor
		end
	end
	return actor
end
function Pose.new() return setmetatable({actors = {}, stored = {}, nextScan = 0}, Pose) end
function Pose:clear(userId)
	local actor = self.actors[userId]
	if actor then release(actor); self.actors[userId] = nil end
end
function Pose:destroy()
	for id in self.actors do self:clear(id) end
	for model, actor in self.stored do release(actor); self.stored[model] = nil end
end
function Pose:stage(data)
	if data.phase == "Cooldown" or data.phase == "Damaged" or data.phase == "Transfer" then self:clear(data.userId); return end
	local actor = self.actors[data.userId]
	if actor and actor.token ~= data.token then self:clear(data.userId); actor = nil end
	if not actor then actor = {token = data.token, motors = {}, transforms = {}}; self.actors[data.userId] = actor end
	actor.data, actor.expires = data, os.clock()+data.duration+2
end
local function punch(actor, data, p, dt)
	if not p.ready or not data.cf then
		for motor, previous in actor.punchC0 do
			if motor.Parent then
				actor.punchC0[motor] = previous:Lerp(motor.C0, 1-math.exp(-14*dt))
				motor.C0 = actor.punchC0[motor]
			end
		end
		return
	end
	local r6 = actor.joints["Right Shoulder"] ~= nil
	for _, side in {-1, 1} do
		local prefix = side == -1 and "Left" or "Right"
		local shoulder = actor.joints[prefix .. (r6 and " Shoulder" or "Shoulder")]
		if not shoulder or not shoulder.Part0 or not shoulder.Part1 then continue end
		local elbow, wrist = actor.joints[prefix.."Elbow"], actor.joints[prefix.."Wrist"]
		local original = actor.motors[shoulder]
		local joint = shoulder.Part0.CFrame:PointToWorldSpace(original.Position)
		local height = data.cf:PointToObjectSpace(joint).Y-0.25
		local contact = Punch.contact(data.cf, side, height)
		local guard = joint+data.cf:VectorToWorldSpace(Vector3.new(-side*0.25, -0.45, -0.65))
		local selected = (data.hit == 2 and side == -1) or (data.hit ~= 2 and side == 1)
		local extension = selected and math.clamp(p.strike, 0, 1) or 0
		local target = guard:Lerp(contact, extension)
		local function set(motor, desired, parentCF)
			local c0 = parentCF:Inverse()*desired*motor.C1
			local previous = actor.punchC0[motor] or motor.C0
			actor.punchC0[motor] = previous:Lerp(c0, 1-math.exp(-35*dt))
			motor.C0, motor.Transform = actor.punchC0[motor], CFrame.new()
		end
		if elbow and wrist and elbow.Part1 and wrist.Part1 then
			local a = (actor.motors[elbow].Position-shoulder.C1.Position).Magnitude
			local forearm = (actor.motors[wrist].Position-elbow.C1.Position).Magnitude
			local tip = Vector3.new(0, -wrist.Part1.Size.Y/2, 0)
			local hand = (tip-wrist.C1.Position).Magnitude
			local bend, endPoint = Punch.bend(joint, target, a, forearm+hand, data.cf:VectorToWorldSpace(Vector3.new(side*0.5, -1, 0)))
			local upperCF = Punch.aim(joint, shoulder.C1.Position, actor.motors[elbow].Position, bend)
			local lowerTip = elbow.C1.Position+(actor.motors[wrist].Position-elbow.C1.Position).Unit*(forearm+hand)
			local lowerCF = Punch.aim(bend, elbow.C1.Position, lowerTip, endPoint)
			local wristPoint = lowerCF:PointToWorldSpace(actor.motors[wrist].Position)
			local handCF = Punch.aim(wristPoint, wrist.C1.Position, tip, endPoint)
			set(shoulder, upperCF, shoulder.Part0.CFrame)
			set(elbow, lowerCF, upperCF)
			set(wrist, handCF, lowerCF)
		else
			local tip = Vector3.new(0, -shoulder.Part1.Size.Y/2, 0)
			-- R6 has a rigid arm; move the shoulder slightly forward for fist contact.
			local reach = (tip-shoulder.C1.Position).Magnitude
			local delta = target-joint
			if delta.Magnitude > reach then joint += delta.Unit*(delta.Magnitude-reach) end
			set(shoulder, Punch.aim(joint, shoulder.C1.Position, tip, target), shoulder.Part0.CFrame)
		end
	end
end
local function animate(actor, data, clock, dt)
	local t = math.clamp((clock-data.startedAt)/data.duration, 0, 1)
	local p = Motion.sample(data.phase, t, clock, data.hit, data.variation)
	local weight = data.phase == "Exit" and (1-t)*(1-t) or 1
	for motor, original in actor.motors do
		if not motor.Parent then continue end
		local name = motor.Name
		local offset = CFrame.new()
		if name:find("Shoulder") then
			local side = name:find("Left") and -1 or 1
			offset = CFrame.Angles(p.shoulder, side*0.04, side*0.08)
		elseif name:find("Elbow") then offset = CFrame.Angles(p.elbow, 0, 0)
		elseif name:find("Hip") then offset = CFrame.Angles(p.leg, 0, 0)
		elseif name:find("Knee") then offset = CFrame.Angles(-p.leg*1.8, 0, 0)
		elseif name == "Neck" then offset = CFrame.Angles(0.08-p.lean, 0, p.roll*0.4)
		elseif name == "RootJoint" or name == "Root" then
			offset = CFrame.new(0, p.bob, -p.forward)*CFrame.Angles(p.lean, 0, p.roll)
		elseif name == "Waist" then offset = CFrame.Angles(p.lean*0.4, 0, p.roll*0.3) end
		offset = CFrame.new():Lerp(offset, weight)
		-- Preserve pose across stage boundaries instead of restarting a sine wave.
		actor.offsets[motor] = actor.offsets[motor]:Lerp(offset, 1-math.exp(-22*dt))
		-- Rotate in the parent body's axes: R6 shoulder C0 axes differ from R15.
		motor.C0 = CFrame.new(original.Position)*actor.offsets[motor]*original.Rotation
		motor.Transform = CFrame.new() -- Applied in PreSimulation, after Animator evaluation.
	end
	punch(actor, data, p, dt)
end
function Pose:step(dt)
	local clock = workspace:GetServerTimeNow()
	for userId, actor in self.actors do
		local player = Players:GetPlayerByUserId(userId)
		local character = player and player.Character
		if not character or not character.Parent or os.clock() > actor.expires then self:clear(userId); continue end
		if actor.character ~= character then
			local token, data, expires = actor.token, actor.data, actor.expires
			self:clear(userId)
			actor = bind(character)
			actor.token, actor.data, actor.expires = token, data, expires
			self.actors[userId] = actor
		end
		animate(actor, actor.data, clock, dt)
	end
	if os.clock() >= self.nextScan then
		self.nextScan = os.clock()+1
		local lab, camera = workspace:FindFirstChild("Phoenix Laboratory"), workspace.CurrentCamera
		if lab and camera then
			for _, chamber in lab:GetChildren() do
				local model = chamber:FindFirstChild("StoredBody")
				local root = model and model:FindFirstChild("HumanoidRootPart")
				if root and (root.Position-camera.CFrame.Position).Magnitude < Config.EffectDistance and not self.stored[model] then
					self.stored[model] = bind(model)
				end
			end
		end
	end
	for model, actor in self.stored do
		local root, camera = model:FindFirstChild("HumanoidRootPart"), workspace.CurrentCamera
		if not model.Parent or not root or not camera or (root.Position-camera.CFrame.Position).Magnitude > Config.EffectDistance then
			release(actor); self.stored[model] = nil
		else animate(actor, {phase = "Storage", duration = 1, startedAt = clock}, clock, dt) end
	end
end
return Pose
