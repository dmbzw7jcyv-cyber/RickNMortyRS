local Config = require(script.Parent.Config)
local Gun = {}
function Gun.create()
	local tool = Instance.new("Tool")
	tool.Name = "Portal Gun"
	tool.CanBeDropped = false
	tool.ToolTip = "Aim and click / tap a surface • automatic A / B"
	tool:SetAttribute("PortalGun", true)
	tool.Grip = CFrame.new(0, -0.15, 0.35) * CFrame.Angles(math.rad(-8), 0, 0)
	local handle
	local function part(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, cf
		p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = tool
		if handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = handle, p, p
		else handle = p end
		return p
	end
	local gray = Color3.fromRGB(173, 178, 176)
	local dark = Color3.fromRGB(49, 54, 52)
	part("Handle", Vector3.new(0.62, 0.42, 1.5), CFrame.new(0, -0.15, 0.75) * CFrame.Angles(-0.2, 0, 0), gray)
	part("RoundedHeel", Vector3.new(0.64, 0.43, 0.55), CFrame.new(0, -0.29, 1.43), gray, nil, Enum.PartType.Ball)
	part("Housing", Vector3.new(1.15, 0.62, 2.4), CFrame.new(0, 0.1, -0.75), gray)
	part("InsetSide", Vector3.new(1.18, 0.34, 1.95), CFrame.new(0, 0.02, -0.82), Color3.fromRGB(116, 121, 118))
	part("TopPlate", Vector3.new(1.05, 0.07, 2.28), CFrame.new(0, 0.445, -0.75), Color3.fromRGB(211, 214, 206))
	part("SwitchBezel", Vector3.new(0.57, 0.08, 0.52), CFrame.new(0, 0.51, -0.05), dark)
	part("RedSwitch", Vector3.new(0.43, 0.08, 0.38), CFrame.new(0, 0.56, -0.05), Color3.fromRGB(218, 51, 41))
	part("ThumbDial", Vector3.new(0.12, 0.48, 0.48), CFrame.new(0, 0.29, 0.56) * CFrame.Angles(0, 0, math.pi/2), dark, nil, Enum.PartType.Cylinder)
	for _, y in {0.53, 1.88} do
		part("ChamberCollar", Vector3.new(0.13, 0.89, 0.89), CFrame.new(0, y, -1.16) * CFrame.Angles(0, 0, math.pi/2), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	local glass = part("ChamberGlass", Vector3.new(1.22, 0.79, 0.79), CFrame.new(0, 1.2, -1.16) * CFrame.Angles(0, 0, math.pi/2), Config.Lime, Enum.Material.Glass, Enum.PartType.Cylinder)
	glass.Transparency = 0.55
	part("ChamberCap", Vector3.new(0.74, 0.35, 0.74), CFrame.new(0, 1.85, -1.16), Config.Lime, Enum.Material.Glass, Enum.PartType.Ball).Transparency = 0.4
	-- Thin green filaments inside the glass suggest suspended unstable fluid.
	for i = 1, 7 do
		local angle = i * 0.85
		part("ChamberFilament", Vector3.new(0.085, 0.24, 0.085),
			CFrame.new(math.cos(angle)*0.24, 0.66+i*0.13, -1.16+math.sin(angle)*0.24) * CFrame.Angles(0, 0, math.sin(angle)*0.3),
			Config.Lime, Enum.Material.Neon, Enum.PartType.Ball)
	end
	for i = 1, 3 do
		part("CoolingSlot", Vector3.new(0.025, 0.13, 0.2), CFrame.new(-0.601, 0.05, -0.7-i*0.3), dark)
	end
	local core = part("EnergyCore", Vector3.new(0.43, 1.05, 0.43), CFrame.new(0, 1.2, -1.16), Config.Green, Enum.Material.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = Config.Green, 7, 0.8, core
	local a = Instance.new("Attachment", core)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(Config.Lime, Config.Green)
	bubbles.Size = NumberSequence.new(0.08)
	bubbles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	bubbles.Lifetime, bubbles.Rate, bubbles.Speed = NumberRange.new(0.3, 0.7), 5, NumberRange.new(0.2, 0.6)
	bubbles.LightEmission, bubbles.Parent = 1, a
	local muzzle = part("Muzzle", Vector3.new(0.53, 0.35, 0.12), CFrame.new(0, 0.15, -1.99), dark, Enum.Material.Metal)
	local attachment = Instance.new("Attachment")
	attachment.Name, attachment.Position, attachment.Parent = "MuzzleAttachment", Vector3.new(0, 0, -0.1), muzzle
	for _, x in {-0.43, 0.43} do
		for _, z in {-1.75, 0.25} do
			part("Screw", Vector3.new(0.09, 0.03, 0.09), CFrame.new(x, 0.493, z), dark, Enum.Material.Metal)
		end
	end
	return tool
end
return Gun
