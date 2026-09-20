local Chamber = {}
function Chamber.build()
	if workspace:FindFirstChild("Portal Test Chamber") then return end
	local model = Instance.new("Model")
	model.Name = "Portal Test Chamber"
	local function block(name, size, pos, portal, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.Anchored = name, size, pos, true
		p.Material, p.Color = Enum.Material.SmoothPlastic, color or Color3.fromRGB(143, 148, 150)
		p:SetAttribute("PortalSurface", portal)
		p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
		return p
	end
	local function label(p, text, face)
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.SizingMode, gui.PixelsPerStud = face or Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 35
		gui.Parent = p
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		t.Text, t.TextColor3, t.TextScaled, t.Font = text, Color3.fromRGB(194, 201, 201), true, Enum.Font.Code
		t.Parent = gui
	end
	block("Laboratory floor", Vector3.new(140, 1, 130), Vector3.new(0, 0.5, 0), true, Color3.fromRGB(54, 58, 61))
	block("Opposing wall A", Vector3.new(90, 24, 2), Vector3.new(0, 13, -48), true)
	block("Opposing wall B", Vector3.new(90, 24, 2), Vector3.new(0, 13, 48), true)
	block("Right-angle wall", Vector3.new(2, 24, 72), Vector3.new(46, 13, 0), true)
	block("Freestanding test face", Vector3.new(24, 18, 2), Vector3.new(-34, 10, 3), true)
	block("Raised deck", Vector3.new(20, 5, 18), Vector3.new(24, 3.5, 22), true)
	block("Drop platform • 34 studs", Vector3.new(18, 2, 14), Vector3.new(-43, 34, -28), true)
	for i = 1, 34 do
		block("Access stair", Vector3.new(8, i, 1.2), Vector3.new(-55, 1+i/2, 20-i*1.2), false, Color3.fromRGB(79, 84, 87))
	end
	block("Stair landing", Vector3.new(10, 2, 9), Vector3.new(-54, 34, -25), false)
	block("Drop landing pad", Vector3.new(16, 0.12, 17), Vector3.new(-40, 1.06, -11), true, Color3.fromRGB(111, 118, 120))
	for _, x in {-64, 64} do
		local stripe = block("Guide strip", Vector3.new(0.15, 0.05, 115), Vector3.new(x, 1.03, 0), false, Color3.fromRGB(122, 130, 132))
		stripe.Material, stripe.CanCollide, stripe.CanQuery = Enum.Material.SmoothPlastic, false, false
	end
	local sign = block("Instructions", Vector3.new(28, 5, 0.2), Vector3.new(0, 21, -46.85), false, Color3.fromRGB(29, 33, 36))
	label(sign, "DIMENSIONAL FLUID LAB\nCLICK / TAP • AUTO A → B\nDROP TEST: STAIRS ON YOUR LEFT", Enum.NormalId.Back)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position, spawn.Anchored = "Lab spawn", Vector3.new(7, 0.3, 7), Vector3.new(0, 1.2, 27), true
	spawn.Neutral, spawn.Duration, spawn.Color = true, 0, Color3.fromRGB(101, 111, 114)
	spawn:SetAttribute("PortalSurface", false)
	spawn.Parent = model
	model.Parent = workspace
end
return Chamber
