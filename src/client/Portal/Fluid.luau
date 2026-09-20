local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config, Math = require(Shared.Config), require(Shared.Math)
local TweenService = game:GetService("TweenService")
local Fluid = {}
Fluid.__index = Fluid
function Fluid.new(effects)
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, {effects.folder}, true
	return setmetatable({effects = effects, drops = {}, params = params}, Fluid)
end
function Fluid:emit(cf, count, collapse)
	if not self.effects:near(cf.Position) then return end
	for _ = 1, count do
		if #self.drops >= Config.MaxDroplets then break end
		local angle = math.random() * math.pi * 2
		local radial = Vector3.new(math.cos(angle) * Config.Width/2, math.sin(angle) * Config.Height/2, 0.2)
		local pos = cf:PointToWorldSpace(radial * (collapse and 0.85 or 1))
		local r = 0.09 + math.random() * 0.16
		local part = self.effects:temporary(math.random() > 0.4 and Config.Green or Config.Lime, Vector3.new(r, r*1.8, r), CFrame.new(pos), 1.6)
		if part then
			local velocity = cf:VectorToWorldSpace(Vector3.new(math.cos(angle)*3, math.sin(angle)*2, 2 + math.random()*4))
			if collapse then velocity += Vector3.new(0, -2, 0) end
			table.insert(self.drops, {part = part, pos = pos, velocity = velocity, age = 0, radius = r})
		end
	end
end
function Fluid:step(dt)
	for i = #self.drops, 1, -1 do
		local d = self.drops[i]
		d.age += dt
		if not d.part.Parent or d.age > 1.2 then
			d.part:Destroy(); table.remove(self.drops, i); continue
		end
		d.velocity += Vector3.new(0, -workspace.Gravity * 0.35, 0) * dt
		local movement = d.velocity * dt
		local hit = workspace:Raycast(d.pos, movement, self.params)
		if hit then
			local size = Vector3.new(d.radius*4.5, d.radius*3.2, 0.035)
			d.part.Size, d.part.CFrame = size, Math.surfaceFrame(hit.Position + hit.Normal*0.035, hit.Normal)
			TweenService:Create(d.part, TweenInfo.new(0.55), {Transparency = 1, Color = Config.Dark, Size = size * 1.5}):Play()
			table.remove(self.drops, i)
		else
			d.pos += movement
			d.part.Position = d.pos
			d.part.Transparency = math.clamp((d.age-0.5)/0.7, 0, 1)
			d.part.Color = Config.Green:Lerp(Config.Dark, math.clamp(d.age/1.5, 0, 1))
		end
	end
end
return Fluid
