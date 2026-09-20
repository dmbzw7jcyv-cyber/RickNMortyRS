local Players = game:GetService("Players")
local Motion = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Motion)
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
	local actor = {character = character, motors = {}, transforms = {}, offsets = {}}
	actor.animate = character:FindFirstChild("Animate")
	if actor.animate and actor.animate:IsA("LocalScript") then actor.wasEnabled = actor.animate.Enabled; actor.animate.Enabled = false
	else actor.animate = nil end
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			actor.motors[motor], actor.transforms[motor], actor.offsets[motor] = motor.C0, motor.Transform, CFrame.new()
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
