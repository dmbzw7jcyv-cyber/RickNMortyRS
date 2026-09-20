local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Motion = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Motion)
local Effects = {}
Effects.__index = Effects
local soundStages = {
	Transfer = {"Transfer"}, Activate = {"Startup", "ElectricalActivation", "Pump"},
	Reconstruct = {"Bubbles"}, Wake = {"Pump"}, Pump = {"Pump"}, Drain = {"Drain"},
	Unlock = {"Locks"}, Open = {"Open", "Steam"}, Malfunction = {"Malfunction"},
	Burst = {"BreakGlass", "LiquidBurst", "Sparks"},
	Cooldown = {"Cooldown"}, Damaged = {"Sparks"},
}
function Effects.new()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "PhoenixClientEffects", workspace
	return setmetatable({folder = folder, records = {}, count = 0}, Effects)
end
function Effects:part(parent, size, cf, color, lifetime, glass)
	if self.count >= Config.MaxTemporaryParts then return nil end
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = "Phoenix visual", size, cf, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Material, p.Transparency = glass and Enum.Material.Glass or Enum.Material.Neon, glass and 0.45 or 0
	if not glass then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, p
	end
	p.Parent = parent
	self.count += 1
	p.Destroying:Once(function() self.count -= 1 end)
	Debris:AddItem(p, lifetime)
	return p
end
function Effects:sound(record, name, looping)
	local id = Config.Sounds[name]
	if not id or id == "" then return nil end
	local sound = Instance.new("Sound")
	sound.Name, sound.SoundId, sound.Volume, sound.RollOffMaxDistance = name, id, looping and 0.18 or 0.4, 90
	sound.Looped, sound.Parent = looping == true, record.host
	sound:Play()
	if not looping then Debris:AddItem(sound, 4) end
	return sound
end
function Effects:clear(id)
	local record = self.records[id]
	if record then
		if record.glassCF then
			local lab = workspace:FindFirstChild("Phoenix Laboratory")
			local chamber = lab and lab:FindFirstChild("Phoenix Chamber " .. id)
			local glass = chamber and chamber:FindFirstChild("TankGlass")
			if glass then glass.CFrame = record.glassCF end
		end
		record.folder:Destroy(); self.records[id] = nil
	end
end
function Effects:record(data)
	local old = self.records[data.chamberId]
	if old and (old.token ~= data.token or old.userId ~= data.userId) then self:clear(data.chamberId); old = nil end
	if old then return old end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Chamber " .. data.chamberId, self.folder
	local host = Instance.new("Part")
	host.Name, host.Size, host.CFrame, host.Transparency = "Effect anchor", Vector3.one*0.1, data.cf*CFrame.new(0, 6, 0), 1
	host.Anchored, host.CanCollide, host.CanTouch, host.CanQuery, host.Parent = true, false, false, false, folder
	local att = Instance.new("Attachment", host)
	att.Position = Vector3.new(0, -2.7, 0)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color, bubbles.LightEmission = ColorSequence.new(Config.Green, Color3.fromRGB(188, 255, 191)), 0.65
	bubbles.Size = NumberSequence.new(0.1, 0.04)
	bubbles.Transparency = NumberSequence.new(0.4, 1)
	bubbles.Lifetime, bubbles.Speed, bubbles.SpreadAngle = NumberRange.new(0.5, 1.2), NumberRange.new(3, 6), Vector2.new(28, 28)
	bubbles.Rate, bubbles.Parent = 0, att
	local top = Instance.new("Attachment", host)
	top.Position = Vector3.new(0, 3, -1.5)
	local sparks = bubbles:Clone()
	sparks.Name, sparks.Rate, sparks.Speed = "Electrical sparks", 0, NumberRange.new(4, 8)
	sparks.Color, sparks.Lifetime, sparks.SpreadAngle = ColorSequence.new(Config.Amber), NumberRange.new(0.15, 0.35), Vector2.new(160, 160)
	sparks.Acceleration, sparks.Parent = Vector3.new(0, -12, 0), top
	local steam = bubbles:Clone()
	steam.Name, steam.Texture, steam.Rate = "Valve steam", "rbxasset://textures/particles/smoke_main.dds", 0
	steam.Size, steam.Transparency, steam.Speed = NumberSequence.new(0.5, 1.5), NumberSequence.new(0.8, 1), NumberRange.new(0.5, 1.5)
	steam.Color, steam.Parent = ColorSequence.new(Color3.fromRGB(193, 218, 197)), top
	local record = {folder = folder, host = host, bubbles = bubbles, sparks = sparks, steam = steam, token = data.token, userId = data.userId, cf = data.cf, cracks = {}, phaseId = 0}
	self.records[data.chamberId] = record
	return record
end
function Effects:crack(record, hit)
	for i = 1, 5 do
		local start = Vector3.new((hit-2)*0.65, 5.5+hit*0.3, -2.95)
		local finish = start + Vector3.new(math.sin(i*2.7+hit)*(0.4+hit*0.35), math.cos(i*2.7)*(0.6+hit*0.4), 0)
		local a, b = record.cf:PointToWorldSpace(start), record.cf:PointToWorldSpace(finish)
		local part = self:part(record.folder, Vector3.new(0.025, 0.025, (a-b).Magnitude), CFrame.lookAt((a+b)/2, b), Color3.fromRGB(211, 251, 215), 7)
		if part then table.insert(record.cracks, part) end
	end
end
function Effects:drips(record)
	for _ = 1, 6 do
		local x, y = (math.random()-0.5)*3.5, 4+math.random()*4
		local part = self:part(record.folder, Vector3.new(0.065, 0.4, 0.035), record.cf*CFrame.new(x, y, -2.72), Config.Green, 1.6)
		if part then TweenService:Create(part, TweenInfo.new(1.2), {CFrame = record.cf*CFrame.new(x, 2.6, -2.72), Transparency = 1}):Play() end
	end
end
function Effects:burst(record)
	for _, part in record.cracks do part:Destroy() end
	table.clear(record.cracks)
	for i = 1, 22 do
		local glass = i <= 8
		local start = record.cf:PointToWorldSpace(Vector3.new((math.random()-0.5)*3.8, 3+math.random()*5, -2.5))
		local finish = record.cf:PointToWorldSpace(Vector3.new((math.random()-0.5)*10, 1.05, -4-math.random()*6))
		local direction = finish-start
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, {self.folder}, true
		local hit = workspace:Raycast(start, direction + Vector3.new(0, -1, 0), params)
		if hit then finish = hit.Position+hit.Normal*0.04 end
		local size = glass and Vector3.new(0.17, 0.35, 0.06) or Vector3.new(0.12, 0.27, 0.12)
		local part = self:part(record.folder, size, CFrame.new(start), glass and Color3.fromRGB(175, 221, 205) or Config.Green, 1.6, glass)
		if part then
			local endCF = CFrame.new(finish)*CFrame.Angles(math.random(), math.random()*3, math.random())
			TweenService:Create(part, TweenInfo.new(0.4), {CFrame = endCF}):Play()
			task.delay(0.4, function()
				if not part.Parent then return end
				if not glass then
					part.Size = Vector3.new(0.65, 0.025, 0.45)
					part.CFrame = hit and CFrame.lookAt(finish, finish+hit.Normal)*CFrame.Angles(math.pi/2, 0, 0) or CFrame.new(finish)
				end
				TweenService:Create(part, TweenInfo.new(0.7), {Transparency = 1}):Play()
			end)
		end
	end
end
function Effects:stage(data)
	local camera = workspace.CurrentCamera
	if data.userId ~= Players.LocalPlayer.UserId and (not camera or (camera.CFrame.Position-data.cf.Position).Magnitude > Config.EffectDistance) then return end
	local record = self:record(data)
	record.phaseId += 1
	record.data, record.expires = data, os.clock()+math.max(5, data.duration+2)
	for _, kind in soundStages[data.phase] or {} do self:sound(record, kind) end
	if data.phase == "Activate" or data.phase == "Reconstruct" then record.bubbles.Rate = 18; record.sparks:Emit(8)
	elseif data.phase == "Drain" then
		self:drips(record)
		TweenService:Create(record.bubbles, TweenInfo.new(data.duration), {Rate = 0}):Play()
	elseif data.phase == "Open" then
		record.steam:Emit(12)
	elseif data.phase == "Malfunction" then
		record.alarm = self:sound(record, "Alarm", true)
	elseif data.phase == "Pound" and data.hit ~= 3 then
		local phaseId = record.phaseId
		task.delay(math.max(0, data.startedAt+data.duration*Motion.Contact-workspace:GetServerTimeNow()), function()
			if record.folder.Parent and record.phaseId == phaseId then
				self:crack(record, data.hit or 1); record.sparks:Emit(6)
				self:sound(record, "HitGlass"); self:sound(record, "CrackGlass")
				record.impactAt = workspace:GetServerTimeNow()
			end
		end)
	elseif data.phase == "Burst" then
		self:sound(record, "HitGlass")
		record.bubbles.Rate = 0
		record.bubbles:Emit(28)
		record.sparks:Emit(16); record.steam:Emit(12)
		self:burst(record)
	elseif data.phase == "Damaged" or data.phase == "Cooldown" then
		record.bubbles.Rate = 0
		if data.phase == "Damaged" then record.sparks:Emit(5) end
		if record.alarm then Debris:AddItem(record.alarm, 0.6); record.alarm = nil end
	end
end
function Effects:step()
	for id, record in self.records do
		if os.clock() > record.expires then self:clear(id); continue end
		local data = record.data
		local lab = workspace:FindFirstChild("Phoenix Laboratory")
		local chamber = lab and lab:FindFirstChild("Phoenix Chamber " .. id)
		local glass = chamber and chamber:FindFirstChild("TankGlass")
		if glass and record.impactAt then
			local elapsed = workspace:GetServerTimeNow()-record.impactAt
			if not record.glassCF then record.glassCF = glass.CFrame end
			if elapsed < 0.22 and data.phase == "Pound" then
				glass.CFrame = record.glassCF*CFrame.new(math.sin(elapsed*65)*0.035*(1-elapsed/0.22), 0, -math.sin(elapsed/0.22*math.pi)*0.09)
			else glass.CFrame = record.glassCF; record.impactAt, record.glassCF = nil, nil end
		end
		if data and (data.phase == "Malfunction" or data.phase == "Pound") then
			local lab = workspace:FindFirstChild("Phoenix Laboratory")
			local model = lab and lab:FindFirstChild("Phoenix Chamber " .. id)
			local lamp = model and model:FindFirstChild("StatusLight")
			if lamp then lamp.Color = math.sin(os.clock()*19) > 0 and Config.Red or Config.Amber end
		end
	end
end
return Effects
