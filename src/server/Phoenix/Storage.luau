-- Cosmetic reserve bodies only; never Players' characters or resurrection authorities.
local Players = game:GetService("Players")
local Storage = {}
function Storage.clear(slot)
	if slot.storedBody then slot.storedBody:Destroy(); slot.storedBody = nil end
	slot.storedSource = nil
end
function Storage.create(slot, character)
	Storage.clear(slot)
	local old = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function() return character:Clone() end)
	character.Archivable = old
	if not ok or not copy then return end
	for _, item in copy:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Tool") or item:IsA("ForceField") or item:IsA("Animator") then item:Destroy()
		elseif item:IsA("BasePart") then
			item.CanCollide, item.CanTouch, item.CanQuery, item.Massless = false, false, false, true
			item:SetAttribute("PortalSurface", false)
		end
	end
	local root, hum = copy:FindFirstChild("HumanoidRootPart"), copy:FindFirstChildOfClass("Humanoid")
	if not root or not hum then copy:Destroy(); return end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Health, hum.AutoRotate = hum.MaxHealth, false
	root.Anchored = true
	local legs = hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight
	local target = slot.cf*CFrame.new(0, slot.floorY+legs+root.Size.Y/2+0.65, 0)
	copy:PivotTo(target*root.CFrame:Inverse()*copy:GetPivot())
	copy.Name, copy.Parent = "StoredBody", slot.model
	slot.storedBody, slot.storedSource = copy, character
end
function Storage.start(lab)
	local bound = {}
	task.spawn(function()
		while lab.folder.Parent do
			for _, slot in lab.slots do
				if not bound[slot] then
					bound[slot] = slot.model:GetAttributeChangedSignal("Phase"):Connect(function()
						if slot.model:GetAttribute("Phase") ~= "Idle" then Storage.clear(slot) end
					end)
				end
				local player = slot.owner and Players:GetPlayerByUserId(slot.owner)
				local char = player and player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local idle = slot.model:GetAttribute("Phase") == "Idle"
				if idle and player and not player:GetAttribute("PhoenixActive") and hum and hum.Health > 0
					and player:HasAppearanceLoaded() then
					if slot.storedSource ~= char then Storage.create(slot, char) end
				else Storage.clear(slot) end
			end
			task.wait(1)
		end
		for slot, connection in bound do connection:Disconnect(); Storage.clear(slot) end
	end)
end
return Storage
