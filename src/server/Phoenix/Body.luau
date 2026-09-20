local TweenService = game:GetService("TweenService")
local Body = {}
function Body.lock(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root, "Phoenix avatar has no Humanoid/root")
	local state = {character = character, humanoid = humanoid, root = root, visuals = {}, tools = {}, tweens = {},
		walk = humanoid.WalkSpeed, power = humanoid.JumpPower, height = humanoid.JumpHeight, rotate = humanoid.AutoRotate}
	character:SetAttribute("PhoenixBusy", true)
	humanoid:UnequipTools()
	humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = 0, 0, 0, false
	root.Anchored = true
	local shield = Instance.new("ForceField")
	shield.Name, shield.Visible, shield.Parent, state.shield = "PhoenixProtection", false, character, shield
	local function hide(item)
		if item:IsA("BasePart") or item:IsA("Decal") then
			state.visuals[item] = item.Transparency
			item.Transparency = 1
		elseif item:IsA("Tool") then state.tools[item] = item.Enabled; item.Enabled = false end
	end
	for _, item in character:GetDescendants() do hide(item) end
	state.connection = character.DescendantAdded:Connect(hide)
	return state
end
function Body.position(state, slot)
	local humanoid, root = state.humanoid, state.root
	local legs = humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or humanoid.HipHeight
	local cf = slot.cf*CFrame.new(0, slot.floorY+legs+root.Size.Y/2+0.65, 0)
	state.character:PivotTo(cf * root.CFrame:Inverse() * state.character:GetPivot())
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
end
function Body.reveal(state, duration)
	if state.connection then state.connection:Disconnect(); state.connection = nil end
	for item, transparency in state.visuals do
		if item.Parent then
			if duration == 0 then item.Transparency = transparency; continue end
			local tween = TweenService:Create(item, TweenInfo.new(duration), {Transparency = transparency})
			table.insert(state.tweens, tween); tween:Play()
		end
	end
end
function Body.restore(state)
	if not state then return end
	if state.connection then state.connection:Disconnect(); state.connection = nil end
	for _, tween in state.tweens do tween:Cancel() end
	for item, value in state.visuals do if item.Parent then item.Transparency = value end end
	for tool, enabled in state.tools do if tool.Parent then tool.Enabled = enabled end end
	if state.shield then state.shield:Destroy() end
	local humanoid, root = state.humanoid, state.root
	if humanoid.Parent then
		humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = state.walk, state.power, state.height, state.rotate
		humanoid.PlatformStand, humanoid.Sit = false, false
	end
	if root.Parent then root.Anchored = false end
	if state.character.Parent then state.character:SetAttribute("PhoenixBusy", false) end
end
return Body
