local Players = game:GetService("Players")
local Pose = {}
Pose.__index = Pose
function Pose.new() return setmetatable({actors = {}}, Pose) end
function Pose:clear(userId)
	local actor = self.actors[userId]
	if not actor then return end
	for motor, cf in actor.motors do if motor.Parent then motor.C0 = cf end end
	if actor.animate and actor.animate.Parent then actor.animate.Enabled = actor.wasEnabled end
	self.actors[userId] = nil
end
function Pose:stage(data)
	if data.phase == "Cooldown" or data.phase == "Damaged" or data.phase == "Transfer" then self:clear(data.userId); return end
	local actor = self.actors[data.userId]
	if actor and actor.token ~= data.token then self:clear(data.userId); actor = nil end
	if not actor then actor = {token = data.token, motors = {}}; self.actors[data.userId] = actor end
	actor.data, actor.expires = data, os.clock()+data.duration+2
end
function Pose:step()
	for userId, actor in self.actors do
		local player = Players:GetPlayerByUserId(userId)
		local character = player and player.Character
		if not character or not character.Parent or os.clock() > actor.expires then self:clear(userId); continue end
		if actor.character ~= character then
			self:clear(userId)
			actor = {token = actor.token, data = actor.data, expires = actor.expires, character = character, motors = {}}
			self.actors[userId] = actor
			actor.animate = character:FindFirstChild("Animate")
			if actor.animate and actor.animate:IsA("LocalScript") then actor.wasEnabled = actor.animate.Enabled; actor.animate.Enabled = false
			else actor.animate = nil end
			for _, motor in character:GetDescendants() do
				if motor:IsA("Motor6D") and (motor.Name:find("Shoulder") or motor.Name == "Neck" or motor.Name == "Waist" or motor.Name == "RootJoint") then
					actor.motors[motor] = motor.C0
				end
			end
		end
		local data = actor.data
		local t = math.clamp((workspace:GetServerTimeNow()-data.startedAt)/data.duration, 0, 1)
		local hit = data.phase == "Pound" and math.sin(t*math.pi)^4 or 0
		for motor, original in actor.motors do
			if not motor.Parent then continue end
			if motor.Name:find("Shoulder") then
				local raise = data.phase == "Pound" and 1.05+hit*0.85 or 0.08*math.sin(t*math.pi)
				motor.C0 = original*CFrame.Angles(raise, 0, 0)
			elseif motor.Name == "Neck" then
				motor.C0 = original*CFrame.Angles(data.phase == "Reconstruct" and 0.18 or -hit*0.14, 0, math.sin(t*math.pi)*0.06)
			else
				local lean = data.phase == "Exit" and data.variation == "Breakout" and math.sin(t*math.pi)*0.3 or hit*0.12
				motor.C0 = original*CFrame.Angles(lean, 0, 0)
			end
		end
	end
end
return Pose
