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
	local portal = {data = data, model = model, core = core, light = light, rim = {}, ribbons = {}, highlights = {}, wisps = {}, phase = data.slot == "B" and 1.4 or 0, spin = data.slot == "B" and -0.7 or 0.85, born = os.clock() - (settled and Config.OpenTime or 0), dripAt = 0}
	-- Matte green ribbons retain contrast; selective neon highlights keep the fluid readable.
	for i = 1, 28 do
		portal.rim[i] = Effects.part(model, Config.Green, Vector3.one, data.cf)
	end
	for arm = 1, 3 do
		for segment = 1, 13 do
			local p = Effects.part(model, arm == 2 and Color3.fromRGB(37, 162, 13) or Color3.fromRGB(109, 224, 28), Vector3.one, data.cf, arm == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
			table.insert(portal.ribbons, {part = p, arm = arm, segment = segment})
		end
	end
	-- Small pale-green flecks ride inside the thick liquid edge, like the reference.
	for i = 1, 10 do
		portal.highlights[i] = Effects.part(model, Color3.fromRGB(177, 255, 112), Vector3.one, data.cf)
	end
	-- Four low-rate emitters share the core; no extra physics Parts or frame connections.
	for i = 1, 4 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = core
		local mist = Instance.new("ParticleEmitter")
		mist.Name = "Green fluid wisp"
		mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
		mist.Color = ColorSequence.new(Config.Green, Config.Dark)
		mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.8), NumberSequenceKeypoint.new(1, 1)})
		mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.65)})
		mist.Rate, mist.Lifetime, mist.Speed = 1.5, NumberRange.new(0.45, 0.85), NumberRange.new(0.3, 0.8)
		mist.SpreadAngle, mist.EmissionDirection = Vector2.new(25, 25), Enum.NormalId.Back
		mist.Rotation, mist.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-35, 35)
		mist.LightEmission, mist.LightInfluence, mist.Parent = 0.65, 0, attachment
		table.insert(portal.wisps, {attachment = attachment, emitter = mist, angle = i * math.pi/2})
	end
	local tag = Instance.new("BillboardGui")
	tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance, tag.AlwaysOnTop, tag.Parent = UDim2.fromOffset(40, 20), Vector3.new(0, 5.65, 0), 35, false, core
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency, text.Text = UDim2.fromScale(1, 1), 1, data.slot
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
	for _, wisp in p.wisps do wisp.emitter.Enabled = false end
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
	local phase = t + p.phase
	local jitter = close * 0.12 * math.sin(now*51)
	local squeeze = 1 - close*0.22
	p.core.Size = Vector3.new(Config.Width * scale * squeeze, Config.Height * scale, 0.1)
	p.core.CFrame, p.core.Transparency = cf, close
	p.core.Color = Config.Dark:Lerp(Color3.fromRGB(23, 121, 12), 0.25+0.2*math.sin(phase*1.7))
	p.light.Brightness = scale * (0.7 + (p.data.slot == "A" and 0.12 or 0) + 0.12*math.sin(phase*7))
	local function rimPoint(angle)
		local wobble = 1 + 0.035*math.sin(angle*5 + phase*3) + 0.02*math.sin(angle*9-phase*4)
		return Vector3.new(math.cos(angle)*Config.Width/2*wobble*scale*squeeze + jitter,
			math.sin(angle)*Config.Height/2*wobble*scale, 0.12)
	end
	-- Span adjacent samples with overlapping tapered-looking ellipsoids, avoiding isolated beads.
	for i, part in p.rim do
		local angle = (i-1)/28 * math.pi*2
		local a, b = rimPoint(angle), rimPoint(angle + math.pi*2/28)
		local delta = b-a
		part.CFrame = cf * CFrame.new((a+b)*0.5) * CFrame.Angles(0, 0, math.atan2(delta.Y, delta.X))
		part.Size = Vector3.new(delta.Magnitude*1.28, (0.68+0.15*math.sin(phase*3+angle*4))*scale, 0.14*scale)
		part.Color = Config.Green:Lerp(Config.Lime, 0.16+0.14*math.sin(angle*3-phase*2))
		part.Transparency = close*0.9
	end
	local function spiralPoint(f, arm)
		local angle = f*math.pi*2.1 + arm*math.pi*2/3 - t*p.spin + p.phase + 0.18*math.sin(f*9+phase*0.9+arm)
		local radius = f*(0.82+math.sin(f*13+phase*1.2+arm)*0.055)*scale
		return Vector3.new(math.cos(angle)*Config.Width/2*radius*squeeze,
			math.sin(angle)*Config.Height/2*radius, 0.18+arm*0.018)
	end
	for _, ribbon in p.ribbons do
		local f = ribbon.segment/13
		local a, b = spiralPoint((ribbon.segment-1)/13, ribbon.arm), spiralPoint(f, ribbon.arm)
		local delta = b-a
		ribbon.part.CFrame = cf * CFrame.new((a+b)*0.5) * CFrame.Angles(0, 0, math.atan2(delta.Y, delta.X))
		ribbon.part.Size = Vector3.new(math.max(0.01, delta.Magnitude*1.32), (0.20+f*0.85)*(0.85+0.15*math.sin(f*16+phase*2+ribbon.arm))*scale, 0.055)
		ribbon.part.Transparency = ribbon.arm == 3 and (0.1+close*0.9) or close
	end
	for i, fleck in p.highlights do
		local angle = i*math.pi*2/10 + t*p.spin*0.12
		local position = rimPoint(angle)
		position = Vector3.new(position.X*0.95, position.Y*0.95, 0.23)
		fleck.CFrame = cf * CFrame.new(position) * CFrame.Angles(0, 0, angle+math.pi/2)
		fleck.Size = Vector3.new((0.18+0.08*math.sin(i*7))*scale, (0.09+0.035*math.sin(i*3))*scale, 0.035)
		fleck.Transparency = math.max(close, 0.15+0.1*math.sin(phase*2+i))
	end
	for _, wisp in p.wisps do
		wisp.attachment.Position = rimPoint(wisp.angle)
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
