local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config = require(Shared.Config)
local Effects = {}
Effects.__index = Effects
function Effects.new(folder)
	return setmetatable({folder = folder, count = 0, shots = {}}, Effects)
end
function Effects:near(position)
	local camera = workspace.CurrentCamera
	return camera and (camera.CFrame.Position-position).Magnitude < Config.EffectDistance
end
function Effects.part(parent, color, size, cf, material)
	local p = Instance.new("Part")
	p.Name, p.Shape = "Portal energy", Enum.PartType.Ball
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Color, p.Material, p.Size, p.CFrame = color, material or Enum.Material.Neon, size, cf
	p.Parent = parent
	return p
end
function Effects:temporary(color, size, cf, lifetime)
	if self.count >= Config.MaxTransientParts then return nil end
	self.count += 1
	local p = Effects.part(self.folder, color, size, cf)
	p.Destroying:Once(function() self.count -= 1 end)
	Debris:AddItem(p, lifetime)
	return p
end
function Effects:sound(kind, position)
	local id = Config.Sounds[kind]
	if id == "" or not self:near(position) then return end
	local host = self:temporary(Config.Green, Vector3.one * 0.05, CFrame.new(position), 5)
	if not host then return end
	host.Transparency = 1
	local sound = Instance.new("Sound")
	sound.SoundId, sound.Volume, sound.RollOffMaxDistance, sound.Parent = id, 0.4, 90, host
	sound:Play()
end
function Effects:burst(position, valid, count)
	if not self:near(position) then return end
	local color = valid and Config.Lime or Color3.fromRGB(255, 155, 45)
	local orb = self:temporary(color, Vector3.one * 0.4, CFrame.new(position), 0.28)
	if orb then TweenService:Create(orb, TweenInfo.new(0.26), {Size = Vector3.one * (valid and 3 or 1.7), Transparency = 1}):Play() end
	for _ = 1, count or 7 do
		local p = self:temporary(color, Vector3.one * 0.16, CFrame.new(position), 0.4)
		if p then
			local offset = Vector3.new(math.random()-0.5, math.random()-0.2, math.random()-0.5) * (valid and 5 or 2.5)
			TweenService:Create(p, TweenInfo.new(0.36), {Position = position + offset, Size = Vector3.one * 0.02, Transparency = 1}):Play()
		end
	end
end
function Effects:shot(data)
	if not self:near(data.from) and not self:near(data.to) then return end
	self:sound("Fire", data.from)
	self:burst(data.from, true, 4)
	local p = self:temporary(Config.Lime, Vector3.new(0.23, 0.23, 1.2), CFrame.new(data.from), data.duration + 0.3)
	if not p then return end
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position, a.Parent, b.Parent = Vector3.new(-0.15, 0, 0), Vector3.new(0.15, 0, 0), p, p
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1, trail.Lifetime = a, b, 0.12
	trail.Color, trail.LightEmission, trail.FaceCamera = ColorSequence.new(Config.Lime, Config.Green), 1, true
	trail.Transparency, trail.Parent = NumberSequence.new(0.15, 1), p
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = Config.Green, 6, 1, p
	table.insert(self.shots, {part = p, data = data})
end
function Effects:step()
	for i = #self.shots, 1, -1 do
		local shot = self.shots[i]
		local data = shot.data
		local t = math.clamp((workspace:GetServerTimeNow()-data.startedAt)/data.duration, 0, 1)
		if not shot.part.Parent then table.remove(self.shots, i); continue end
		local position = data.from:Lerp(data.to, t)
		shot.part.CFrame = (data.to-data.from).Magnitude > 0.01 and CFrame.lookAt(position, position + (data.to-data.from).Unit) or CFrame.new(position)
		if t >= 1 then
			shot.part.Transparency = 1
			table.remove(self.shots, i)
		end
	end
end
return Effects
