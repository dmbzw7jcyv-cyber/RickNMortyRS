local Players = game:GetService("Players")

local AvatarStyle = {}

local SKIN = Color3.fromRGB(190, 181, 166)
local HAIR = Color3.fromRGB(139, 218, 231)
local SHIRT = Color3.fromRGB(121, 211, 202)
local COAT = Color3.fromRGB(238, 239, 235)
local PANTS = Color3.fromRGB(105, 78, 42)
local SHOES = Color3.fromRGB(37, 39, 39)

local function visual(folder, name, size, localCF, color, weldTo, className)
	local part = Instance.new(className or "Part")
	part.Name, part.Size, part.CFrame, part.Color = name, size, weldTo.CFrame*localCF, color
	part.Material, part.Anchored, part.Massless = Enum.Material.SmoothPlastic, false, true
	part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false, false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part:SetAttribute("PortalSurface", false)
	part.Parent = folder
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = weldTo, part, part
	return part
end

local function face(folder, head)
	local oldFace = head:FindFirstChild("RickFace")
	if oldFace then oldFace:Destroy() end
	for _, item in head:GetChildren() do
		if item:IsA("Decal") and item.Face == Enum.NormalId.Front then item:Destroy() end
	end
	-- Baked mesh faces and SurfaceAppearance maps survive decal transparency changes.
	if head:IsA("MeshPart") then head.TextureID = "" end
	for _, item in head:GetChildren() do
		if item:IsA("SurfaceAppearance") then item:Destroy()
		elseif item:IsA("SpecialMesh") then item.TextureId = "" end
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.CanvasSize, gui.LightInfluence = "RickFace", Enum.NormalId.Front, Vector2.new(240, 240*head.Size.Y/head.Size.X), 0
	-- SurfaceGui must descend from its BasePart (or PlayerGui) to render.
	gui.Adornee, gui.Parent = head, head
	local backing = Instance.new("Frame")
	backing.Name, backing.Size, backing.BackgroundColor3 = "FaceBacking", UDim2.fromScale(1, 1), SKIN
	backing.BorderSizePixel, backing.ZIndex, backing.Parent = 0, 1, gui
	Instance.new("UICorner", backing).CornerRadius = UDim.new(0.14, 0)
	local function oval(name, position, size, color, z)
		local frame = Instance.new("Frame")
		frame.Name, frame.Position, frame.Size = name, position, size
		frame.BackgroundColor3, frame.BorderColor3, frame.BorderSizePixel, frame.ZIndex = color, Color3.fromRGB(40, 40, 38), 0, z or 2
		Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
		frame.Parent = gui
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio, aspect.DominantAxis, aspect.Parent = 1, Enum.DominantAxis.Width, frame
		local stroke = Instance.new("UIStroke")
		stroke.Color, stroke.Thickness, stroke.Parent = Color3.fromRGB(55, 54, 50), 1, frame
		return frame
	end
	local left, right = oval("LeftEye", UDim2.fromScale(0.255, 0.30), UDim2.fromScale(0.22, 0.22), Color3.fromRGB(247, 247, 240)), oval("RightEye", UDim2.fromScale(0.525, 0.30), UDim2.fromScale(0.22, 0.22), Color3.fromRGB(247, 247, 240))
	for _, eye in {left, right} do
		local pupil = oval("Pupil", UDim2.fromScale(0.45, 0.44), UDim2.fromScale(0.10, 0.10), Color3.fromRGB(26, 27, 25), 3)
		pupil.BorderSizePixel, pupil.Parent = 0, eye
	end
	local brow = Instance.new("Frame")
	brow.Name, brow.Position, brow.Size = "Brow", UDim2.fromScale(0.25, 0.18), UDim2.fromScale(0.5, 0.025)
	brow.ZIndex = 3
	brow.BackgroundColor3, brow.BorderSizePixel, brow.Rotation, brow.Parent = Color3.fromRGB(52, 54, 50), 0, 0, gui
	local nose = Instance.new("TextLabel")
	nose.Name, nose.Position, nose.Size, nose.BackgroundTransparency = "Nose", UDim2.fromScale(0.38, 0.48), UDim2.fromScale(0.24, 0.24), 1
	nose.ZIndex = 3
	nose.Text, nose.TextColor3, nose.TextScaled, nose.Font, nose.Parent = "⌞", Color3.fromRGB(63, 61, 56), true, Enum.Font.Gotham, gui
	local mouth = Instance.new("Frame")
	mouth.Name, mouth.Position, mouth.Size = "Mouth", UDim2.fromScale(0.35, 0.76), UDim2.fromScale(0.3, 0.018)
	mouth.ZIndex = 3
	mouth.BackgroundColor3, mouth.BorderSizePixel, mouth.Parent = Color3.fromRGB(56, 54, 51), 0, gui
end

local function hair(folder, head)
	-- Wedge triangles lie in their Y/Z plane: put thin local X along head depth.
	-- The old orientation exposed the rectangular edge, producing flat spokes.
	local scale = head.Size.X/2
	for index = 1, 9 do
		local angle = math.rad(-22+(index-1)*28)
		local radial = Vector3.new(math.cos(angle), math.sin(angle), 0)
		local tangent = Vector3.new(-math.sin(angle), math.cos(angle), 0)
		local length = (index%2 == 0 and 0.65 or 0.85)*scale
		local pos = Vector3.new(math.cos(angle)*head.Size.X*0.49, math.sin(angle)*head.Size.Y*0.48+0.1*scale, head.Size.Z*0.36)+radial*length*0.22
		local cf = CFrame.fromMatrix(pos, Vector3.zAxis, radial, tangent)
		visual(folder, "HairSpike", Vector3.new(0.38*scale, length, 0.72*scale), cf, HAIR, head, "WedgePart")
	end
	visual(folder, "HairBack", Vector3.new(head.Size.X*1.08, head.Size.Y*1.06, 0.22*scale), CFrame.new(0, 0.12*scale, head.Size.Z*0.43), HAIR, head)
end

local function recolorBody(character)
	for _, item in character:GetDescendants() do
		if not item:IsA("BasePart") then continue end
		local name = item.Name
		if name == "Head" or name:find("Hand") then item.Color = SKIN
		elseif name:find("Arm") then item.Color = COAT
		elseif name:find("Leg") then item.Color = PANTS
		elseif name:find("Foot") then item.Color = SHOES
		elseif name:find("Torso") then item.Color = SHIRT end
	end
end

function AvatarStyle.apply(character)
	if not character or not character.Parent then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not humanoid or not head or not torso then return false end
	local old = character:FindFirstChild("RickStyle")
	if old then old:Destroy() end
	for _, item in character:GetChildren() do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then item:Destroy() end
	end
	recolorBody(character)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RickStyle", character
	face(folder, head)
	hair(folder, head)
	local front = -torso.Size.Z/2-0.075
	visual(folder, "CyanShirt", Vector3.new(torso.Size.X*0.45, torso.Size.Y*0.98, 0.12), CFrame.new(0, 0, front), SHIRT, torso)
	visual(folder, "CoatLeft", Vector3.new(torso.Size.X*0.25, torso.Size.Y, 0.14), CFrame.new(-torso.Size.X*0.37, 0, front-0.02), COAT, torso)
	visual(folder, "CoatRight", Vector3.new(torso.Size.X*0.25, torso.Size.Y, 0.14), CFrame.new(torso.Size.X*0.37, 0, front-0.02), COAT, torso)
	visual(folder, "CoatBack", Vector3.new(torso.Size.X*0.96, torso.Size.Y, 0.12), CFrame.new(0, 0, torso.Size.Z/2+0.07), COAT, torso)
	local hips = character:FindFirstChild("LowerTorso") or torso
	local tailLength = torso.Size.Y*0.95
	local tailY = -hips.Size.Y/2-tailLength/2+0.1
	for _, side in {-1, 1} do
		local name = side == -1 and "CoatTailLeft" or "CoatTailRight"
		visual(folder, name, Vector3.new(torso.Size.X*0.30, tailLength, 0.10), CFrame.new(side*torso.Size.X*0.35, tailY, -hips.Size.Z/2-0.09)*CFrame.Angles(0, 0, side*0.035), COAT, hips)
		visual(folder, "CoatSide", Vector3.new(0.10, tailLength, hips.Size.Z+0.16), CFrame.new(side*torso.Size.X*0.49, tailY, 0), COAT, hips)
		-- Thin, slanted lapels face forward instead of showing the wedge's square edge.
		local cf = CFrame.new(side*torso.Size.X*0.23, torso.Size.Y*0.20, front-0.11)*CFrame.Angles(0, 0, side*0.30)
		visual(folder, "Lapel", Vector3.new(torso.Size.X*0.12, torso.Size.Y*0.56, 0.065), cf, COAT, torso)
	end
	visual(folder, "CoatSkirtBack", Vector3.new(torso.Size.X*0.98, tailLength, 0.10), CFrame.new(0, tailY, hips.Size.Z/2+0.09), COAT, hips)
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		for _, name in {"Left Arm", "Right Arm"} do
			local arm = character:FindFirstChild(name)
			if arm then visual(folder, "Hand", Vector3.new(arm.Size.X*0.9, 0.38, arm.Size.Z*0.9), CFrame.new(0, -arm.Size.Y/2+0.18, 0), SKIN, arm) end
		end
		for _, name in {"Left Leg", "Right Leg"} do
			local leg = character:FindFirstChild(name)
			if leg then visual(folder, "Shoe", Vector3.new(leg.Size.X*1.03, 0.42, leg.Size.Z*1.45), CFrame.new(0, -leg.Size.Y/2+0.2, -0.18), SHOES, leg) end
		end
	end
	character:SetAttribute("RickStyled", true)
	return true
end

function AvatarStyle.start()
	local function playerAdded(player)
		local function characterAdded(character)
			task.defer(function() AvatarStyle.apply(character) end)
		end
		player.CharacterAdded:Connect(characterAdded)
		player.CharacterAppearanceLoaded:Connect(AvatarStyle.apply)
		if player.Character then characterAdded(player.Character) end
	end
	Players.PlayerAdded:Connect(playerAdded)
	for _, player in Players:GetPlayers() do playerAdded(player) end
end

return AvatarStyle
