local Players = game:GetService("Players")
local Model = require(script.Parent.Model)
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Lab = {}
function Lab.build()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Phoenix Laboratory", workspace
	local function block(name, size, pos, color, portal)
		local part = Model.part(folder, name, size, CFrame.new(pos), color, Enum.Material.SmoothPlastic)
		part:SetAttribute("PortalSurface", portal == true)
		return part
	end
	local floor = block("Lab floor", Vector3.new(128, 1, 110), Vector3.new(0, 0.5, 125), Color3.fromRGB(48, 53, 54), true)
	block("Walkway from portal chamber", Vector3.new(24, 1, 14), Vector3.new(-56, 0.5, 66), Color3.fromRGB(80, 85, 83), true)
	block("Portal wall west", Vector3.new(1, 20, 55), Vector3.new(-64, 11, 111), Color3.fromRGB(139, 148, 143), true)
	block("Portal wall east", Vector3.new(1, 20, 55), Vector3.new(64, 11, 111), Color3.fromRGB(139, 148, 143), true)
	local back = block("Equipment backdrop", Vector3.new(128, 18, 1), Vector3.new(0, 10, 153), Color3.fromRGB(46, 55, 48), true)
	local header = block("Phoenix sign", Vector3.new(29, 3, 0.25), Vector3.new(0, 15, 152.3), Color3.fromRGB(22, 28, 25), false)
	Model.label(header, "PHOENIX PROTOCOL\nCONSCIOUSNESS STORAGE / EXPERIMENTAL", nil, Config.Green)
	for _, x in {-52, 52} do
		local console = block("Lab console", Vector3.new(7, 3, 3), Vector3.new(x, 2.5, 90), Color3.fromRGB(64, 71, 65), false)
		Model.label(console, "CONTINUITY ARRAY\nBIO-LINK ACTIVE", Enum.NormalId.Top)
		block("Spare components", Vector3.new(3, 3, 4), Vector3.new(x, 2.5, 97), Color3.fromRGB(86, 88, 69), false)
	end
	local safe = Instance.new("SpawnLocation")
	safe.Name, safe.Size, safe.CFrame = "Phoenix Emergency Landing", Vector3.new(6, 0.2, 6), CFrame.new(0, 1.2, 90)
	safe.Anchored, safe.Neutral, safe.Duration, safe.Transparency, safe.CanCollide = true, true, 0, 1, false
	safe:SetAttribute("PortalSurface", false)
	safe.Parent = folder
	local death = block("Death Test Block", Vector3.new(8, 0.8, 7), Vector3.new(26, 1.4, 90), Config.Red, false)
	death.Material = Enum.Material.DiamondPlate
	for i = -3, 3 do
		local stripe = block("Hazard stripe", Vector3.new(0.65, 0.04, 6.4), Vector3.new(26+i, 1.83, 90), i%2 == 0 and Color3.fromRGB(245, 165, 32) or Color3.fromRGB(26, 26, 24), false)
		stripe.CanCollide, stripe.CanTouch, stripe.CanQuery = false, false, false
	end
	local warning = block("Death test sign", Vector3.new(8, 4, 0.25), Vector3.new(26, 4, 94), Color3.fromRGB(35, 27, 23), false)
	Model.label(warning, "DEATH TEST\nSTEP HERE TO DIE\nPHOENIX TEST", nil, Config.Amber)
	for _, x in {21.5, 30.5} do
		local lightPart = block("Warning beacon", Vector3.new(0.4, 1, 0.4), Vector3.new(x, 2, 90), Config.Amber, false)
		lightPart.Material = Enum.Material.Neon
	end
	death.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player and player.Character == character and humanoid and humanoid.Health > 0 and root
			and not character:GetAttribute("PhoenixBusy") and (root.Position-death.Position).Magnitude < 10 then
			humanoid.Health = 0 -- The normal Humanoid.Died listener owns all resurrection logic.
		end
	end)
	local lab = {folder = folder, safe = safe, slots = {}}
	function lab:create(index)
		local row = math.floor((index-1)/Config.Columns)
		local endZ = 180+row*Config.Spacing
		floor.Size, floor.Position = Vector3.new(128, 1, endZ-70), Vector3.new(0, 0.5, (endZ+70)/2)
		back.Position = Vector3.new(0, 10, 153+row*Config.Spacing)
		header.Position = Vector3.new(0, 15, back.Position.Z-0.7)
		return Model.build(folder, index)
	end
	for i = 1, Config.InitialChambers do table.insert(lab.slots, lab:create(i)) end
	return lab
end
return Lab
