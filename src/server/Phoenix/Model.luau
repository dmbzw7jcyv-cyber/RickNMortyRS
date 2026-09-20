local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Model = {}
local metal, dark = Color3.fromRGB(75, 83, 79), Color3.fromRGB(30, 37, 34)
function Model.part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Anchored = name, size, cf, true
	p.Color, p.Material = color or metal, material or Enum.Material.Metal
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p:SetAttribute("PortalSurface", false)
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
function Model.label(part, text, face, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.Parent = face or Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, part
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Font = UDim2.fromScale(1, 1), 1, Enum.Font.Code
	label.Text, label.TextColor3, label.TextScaled, label.TextWrapped = text, color or Config.Green, true, true
	label.Parent = gui
	return label
end
function Model.build(parent, index)
	local col, row = (index-1)%Config.Columns, math.floor((index-1)/Config.Columns)
	local cf = CFrame.new(Config.Origin + Vector3.new((col-(Config.Columns-1)/2)*Config.Spacing, 0, row*Config.Spacing))
	local model = Instance.new("Model")
	model.Name = "Phoenix Chamber " .. index
	model:SetAttribute("ChamberId", index)
	local function p(name, size, pos, color, material, shape)
		return Model.part(model, name, size, cf*CFrame.new(pos), color, material, shape)
	end
	local function cylinder(name, diameter, height, pos, color, material)
		return Model.part(model, name, Vector3.new(height, diameter, diameter), cf*CFrame.new(pos)*CFrame.Angles(0, 0, math.pi/2), color, material, Enum.PartType.Cylinder)
	end
	cylinder("Foundation", 8, 0.75, Vector3.new(0, 1.4, 0), dark)
	cylinder("Lower pressure assembly", 6.8, 0.7, Vector3.new(0, 2.05, 0))
	cylinder("Upper pressure assembly", 6.8, 0.8, Vector3.new(0, 11.1, 0))
	cylinder("Crown", 5.7, 0.4, Vector3.new(0, 11.7, 0), dark)
	local glass = cylinder("TankGlass", 5.9, 8, Vector3.new(0, 6.5, 0), Color3.fromRGB(152, 201, 185), Enum.Material.SmoothPlastic)
	glass.Transparency, glass.CanCollide, glass.CanQuery, glass.CastShadow = 0.88, false, false, false
	local dome = p("GlassDome", Vector3.new(5.9, 2.3, 5.9), Vector3.new(0, 10.35, 0), glass.Color, Enum.Material.SmoothPlastic)
	dome.Transparency, dome.CanCollide, dome.CanQuery, dome.CastShadow = 0.88, false, false, false
	local sphere = Instance.new("SpecialMesh")
	sphere.MeshType, sphere.Parent = Enum.MeshType.Sphere, dome
	local fluid = cylinder("Fluid", 5.45, 0.08, Vector3.new(0, 2.55, 0), Config.Fluid, Enum.Material.SmoothPlastic)
	fluid.Transparency, fluid.CanCollide, fluid.CanQuery, fluid.CastShadow = 0.65, false, false, false
	local surface = cylinder("FluidSurface", 5.45, 0.06, Vector3.new(0, 10.15, 0), Color3.fromRGB(137, 239, 160), Enum.Material.Neon)
	surface.Transparency, surface.CanCollide, surface.CanTouch, surface.CanQuery = 0.18, false, false, false
	local bubbleAnchor = Instance.new("Attachment", model.Foundation)
	bubbleAnchor.CFrame = model.Foundation.CFrame:ToObjectSpace(cf*CFrame.new(0, 3, 0))
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name, bubbles.Texture = "Storage bubbles", "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color, bubbles.Size = ColorSequence.new(Color3.fromRGB(188, 255, 211)), NumberSequence.new(0.09, 0.04)
	bubbles.Transparency, bubbles.LightEmission = NumberSequence.new(0.25, 1), 0.35
	bubbles.Lifetime, bubbles.Speed, bubbles.SpreadAngle = NumberRange.new(2, 3), NumberRange.new(2, 2.6), Vector2.new(12, 12)
	bubbles.Rate, bubbles.Parent = 7, bubbleAnchor
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = Config.Green, 13, 0.3, fluid
	local locks = {}
	for _, x in {-2.65, 2.65} do
		p("Glass frame", Vector3.new(0.17, 8.3, 0.2), Vector3.new(x, 6.5, 0.6))
		local lock = p("Lock", Vector3.new(0.6, 0.6, 0.8), Vector3.new(x, 3.1, -1.1), dark)
		table.insert(locks, {part = lock, cf = lock.CFrame, side = math.sign(x)})
	end
	for i = 1, 8 do
		local a = i*math.pi/4
		cylinder("Base bolt", 0.18, 0.14, Vector3.new(math.cos(a)*3.15, 2.45, math.sin(a)*3.15), Color3.fromRGB(131, 139, 131))
	end
	p("Pump housing", Vector3.new(1.8, 3.2, 2), Vector3.new(4.1, 3.1, 0.2), Color3.fromRGB(99, 105, 79))
	local leak = Instance.new("ParticleEmitter")
	leak.Name, leak.Texture = "Slow coolant leak", "rbxasset://textures/particles/sparkles_main.dds"
	leak.Color, leak.Size, leak.Transparency = ColorSequence.new(Config.Green), NumberSequence.new(0.07), NumberSequence.new(0.3, 1)
	leak.Rate, leak.Lifetime, leak.Speed = 0.5, NumberRange.new(0.35, 0.6), NumberRange.new(0.2, 0.4)
	leak.Acceleration, leak.EmissionDirection, leak.LightEmission = Vector3.new(0, -9, 0), Enum.NormalId.Bottom, 0.5
	local leakPoint = Instance.new("Attachment", model["Pump housing"])
	leakPoint.Position, leak.Parent = Vector3.new(0.8, -1.2, 0), leakPoint
	for i = 1, 4 do p("Pump vent", Vector3.new(1.3, 0.12, 0.08), Vector3.new(4.1, 2.3+i*0.42, -0.85), dark) end
	cylinder("Feed pipe", 0.3, 8.2, Vector3.new(3.8, 7.6, 1.6), Color3.fromRGB(121, 112, 78))
	Model.part(model, "Pipe elbow", Vector3.new(4.1, 0.3, 0.3), cf*CFrame.new(1.9, 11.5, 1.6), metal, Enum.Material.Metal, Enum.PartType.Cylinder)
	p("Relay box", Vector3.new(1.6, 1.9, 0.7), Vector3.new(-4.4, 5, 1.2), dark)
	for i = 1, 2 do
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Position, b.Position = Vector3.new(-0.5+i*0.3, 0.7, 0), Vector3.new(0, 0.3, 0)
		a.Parent, b.Parent = model["Relay box"], model["Pump housing"]
		local hose = Instance.new("Beam")
		hose.Attachment0, hose.Attachment1, hose.Width0, hose.Width1 = a, b, 0.13, 0.13
		hose.CurveSize0, hose.CurveSize1, hose.Segments, hose.FaceCamera = 2.6, -2, 8, true
		hose.Color, hose.Parent = ColorSequence.new(i == 1 and dark or Color3.fromRGB(133, 70, 38)), model
	end
	local screen = p("Panel", Vector3.new(2.9, 1.6, 0.2), Vector3.new(-4.5, 3.3, -1.2), dark)
	local status = Model.label(screen, "PHOENIX / " .. index .. "\nSTANDBY")
	local lamp = p("StatusLight", Vector3.new(0.4, 0.4, 0.2), Vector3.new(-4.5, 4.4, -1.2), Config.Green, Enum.Material.Neon)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.CFrame = "ReconstructionSpawn", Vector3.new(1, 0.1, 1), cf*CFrame.new(0, 2.5, 0)
	spawn.Anchored, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery, spawn.Transparency = true, false, false, false, 1
	spawn.Neutral, spawn.Duration = true, 0
	spawn:SetAttribute("PortalSurface", false)
	spawn.Parent = model
	model.PrimaryPart = model.Foundation
	model.Parent = parent
	return {id = index, model = model, cf = cf, fluid = fluid, light = light, glass = glass, dome = dome,
		glassCF = glass.CFrame, domeCF = dome.CFrame, locks = locks, status = status, lamp = lamp, spawn = spawn,
		surface = surface, bubbles = bubbles, tweens = {}, revision = 0, owner = nil, floorY = 2.55}
end
return Model
