local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config = require(Shared.Config)
local Effects = require(script.Parent.Effects)
local Renderer = {}
Renderer.__index = Renderer
function Renderer.new(effects, fluid)
	return setmetatable({effects = effects, fluid = fluid, portals = {}, known = {}, closing = {}, elapsed = 0, cullAt = 0}, Renderer)
end
function Renderer:make(data, settled)
	self:close(data.key, true)
	self.known[data.key] = data
	local count = 0
	for _ in self.portals do count += 1 end
	if count < Config.MaxVisiblePortals and self.effects:near(data.cf.Position) then self:materialize(data, settled) end
end
function Renderer:materialize(data, settled)
	local model = Instance.new("Model")
	model.Name, model.Parent = "Liquid portal " .. data.key, self.effects.folder
	local core = Effects.part(model, Config.Dark, Vector3.new(Config.Width, Config.Height, 0.12), data.cf, Enum.Material.SmoothPlastic)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows, light.Parent = Config.Green, 15, 1.15, false, core
	local portal = {data = data, model = model, core = core, light = light, rim = {}, ribbons = {}, born = os.clock() - (settled and Config.OpenTime or 0), dripAt = 0}
	-- Matte green ribbons retain contrast; selective neon highlights keep the fluid readable.
	for i = 1, 28 do
		portal.rim[i] = Effects.part(model, i % 4 == 0 and Config.Lime or Config.Green, Vector3.one, data.cf)
	end
	for arm = 1, 3 do
		for segment = 1, 13 do
			local p = Effects.part(model, arm == 2 and Color3.fromRGB(81, 199, 5) or Color3.fromRGB(156, 236, 14), Vector3.one, data.cf, Enum.Material.SmoothPlastic)
			table.insert(portal.ribbons, {part = p, arm = arm, segment = segment})
		end
	end
	local tag = Instance.new("BillboardGui")
	tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance, tag.AlwaysOnTop, tag.Parent = UDim2.fromOffset(85, 24), Vector3.new(0, 6, 0), 55, false, core
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency, text.Text = UDim2.fromScale(1, 1), 1, "PORTAL " .. data.slot
	text.TextColor3, text.TextSize, text.Font, text.Parent = Config.Lime, 13, Enum.Font.Code, tag
	self.portals[data.key] = portal
	if not settled then
		self.fluid:emit(data.cf, 12, false)
		self.effects:sound("Open", data.cf.Position)
	end
	self:animate(portal, os.clock())
end
function Renderer:close(key, immediate)
	self.known[key] = nil
	local p = self.portals[key]
	if not p then return end
	self.portals[key] = nil
	if immediate then p.model:Destroy(); return end
	p.closedAt = os.clock()
	table.insert(self.closing, p)
	self.fluid:emit(p.data.cf, 19, true)
	self.effects:sound("Close", p.data.cf.Position)
end
function Renderer:reset()
	for _, p in self.portals do p.model:Destroy() end
	for _, p in self.closing do p.model:Destroy() end
	table.clear(self.portals)
	table.clear(self.known)
	table.clear(self.closing)
end
function Renderer:animate(p, now)
	local t = now - p.born
	local open = math.clamp(t / Config.OpenTime, 0, 1)
	local close = p.closedAt and math.clamp((now-p.closedAt)/Config.CloseTime, 0, 1) or 0
	local scale = math.max(0.015, (1-(1-open)^3) * (1-close)^1.5)
	local cf = p.data.cf
	local jitter = close * 0.18 * math.sin(now*71)
	p.core.Size = Vector3.new(Config.Width * scale, Config.Height * scale, 0.1)
	p.core.CFrame, p.core.Transparency = cf, close
	p.light.Brightness = scale * (0.85 + 0.16*math.sin(now*9))
	for i, part in p.rim do
		local angle = i/28 * math.pi*2
		local wobble = 1 + 0.045*math.sin(angle*5 + t*4) + 0.025*math.sin(angle*9-t*6)
		local x = math.cos(angle) * Config.Width/2 * wobble * scale + jitter
		local y = math.sin(angle) * Config.Height/2 * wobble * scale
		local tangent = math.atan2(Config.Height*math.cos(angle), -Config.Width*math.sin(angle))
		part.CFrame = cf * CFrame.new(x, y, 0.1 + 0.045*math.sin(angle*3+t*4)) * CFrame.Angles(0, 0, tangent)
		part.Size = Vector3.new(1.18*scale, (0.36 + 0.12*math.sin(t*7+angle*4))*scale, 0.15*scale)
		part.Transparency = close * 0.9
	end
	for _, ribbon in p.ribbons do
		local f = ribbon.segment/13
		local angle = f*math.pi*2.1 + ribbon.arm*math.pi*2/3 - t*0.85
		local radius = f * (0.86 + math.sin(f*13+t*2)*0.045) * scale
		local x, y = math.cos(angle)*Config.Width/2*radius, math.sin(angle)*Config.Height/2*radius
		local tangent = math.atan2(Config.Height*math.cos(angle), -Config.Width*math.sin(angle))
		ribbon.part.CFrame = cf * CFrame.new(x, y, 0.16 + ribbon.arm*0.012) * CFrame.Angles(0, 0, tangent)
		ribbon.part.Size = Vector3.new((0.4+f*1.5)*scale, (0.12+f*0.22)*scale, 0.055)
		ribbon.part.Transparency = close
	end
end
function Renderer:step(dt)
	self.elapsed += dt
	if self.elapsed < 1/30 then return end
	self.elapsed = 0
	local now = os.clock()
	if now >= self.cullAt then
		self.cullAt = now + 0.3
		local camera = workspace.CurrentCamera
		if camera then
			local nearest = {}
			for key, data in self.known do
				local distance = (data.cf.Position-camera.CFrame.Position).Magnitude
				if distance < Config.EffectDistance then table.insert(nearest, {key = key, data = data, distance = distance}) end
			end
			table.sort(nearest, function(a, b) return a.distance < b.distance end)
			local keep = {}
			for i = 1, math.min(#nearest, Config.MaxVisiblePortals) do keep[nearest[i].key] = nearest[i].data end
			for key, p in self.portals do
				if not keep[key] then p.model:Destroy(); self.portals[key] = nil end
			end
			for key, data in keep do if not self.portals[key] then self:materialize(data, true) end end
		end
	end
	for _, p in self.portals do
		if self.effects:near(p.data.cf.Position) then
			self:animate(p, now)
			if now > p.dripAt then
				p.dripAt = now + 0.5 + math.random()*0.7
				self.fluid:emit(p.data.cf, 1, false)
			end
		end
	end
	for i = #self.closing, 1, -1 do
		local p = self.closing[i]
		if now-p.closedAt >= Config.CloseTime then
			p.model:Destroy(); table.remove(self.closing, i)
		else
			self:animate(p, now)
			if not p.leaked and now-p.closedAt > 0.22 then
				p.leaked = true
				self.fluid:emit(p.data.cf * CFrame.new(0, -1, 0), 7, true)
			end
		end
	end
end
return Renderer
