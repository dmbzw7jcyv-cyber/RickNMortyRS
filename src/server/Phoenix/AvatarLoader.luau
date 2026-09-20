-- LoadCharacterAsync is serialized and bounded. Last good rig is cached for service failures.
local StarterPlayer = game:GetService("StarterPlayer")
local Loader = {}
function Loader.cache(state, character)
	local old = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function() return character:Clone() end)
	character.Archivable = old
	if not ok or not copy then return end
	for _, child in copy:GetChildren() do
		if child:IsA("Tool") or child:IsA("ForceField") then child:Destroy() end
	end
	copy:SetAttribute("PhoenixBusy", nil)
	if state.template then state.template:Destroy() end
	state.template = copy
end
local function emergencyRig()
	-- Offline R6 fallback is used only when no prior avatar exists and Roblox loading fails.
	local model = Instance.new("Model")
	local function part(name, size, position)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position
		p.Color, p.CanCollide, p.Parent = Color3.fromRGB(141, 166, 143), false, model
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
	root.Transparency = 1
	local torso = part("Torso", Vector3.new(2, 2, 1), root.Position)
	torso.CanCollide = true
	local function joint(name, a, b, c0, c1)
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1, m.C0, m.C1, m.Parent = name, a, b, c0, c1, a
	end
	joint("RootJoint", root, torso, CFrame.new(), CFrame.new())
	joint("Neck", torso, part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0)), CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	for _, side in {-1, 1} do
		local name = side == -1 and "Left" or "Right"
		joint(name .. " Shoulder", torso, part(name .. " Arm", Vector3.new(1, 2, 1), Vector3.new(side*1.5, 3, 0)), CFrame.new(side*1, 0.5, 0), CFrame.new(-side*0.5, 0.5, 0))
		joint(name .. " Hip", torso, part(name .. " Leg", Vector3.new(1, 2, 1), Vector3.new(side*0.5, 1, 0)), CFrame.new(side*0.5, -1, 0), CFrame.new(0, 1, 0))
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType, humanoid.Parent = Enum.HumanoidRigType.R6, model
	Instance.new("Animator", humanoid)
	model.PrimaryPart = root
	for _, child in StarterPlayer.StarterCharacterScripts:GetChildren() do child:Clone().Parent = model end
	return model
end
function Loader.fallback(player, state, cf)
	local character = state.template and state.template:Clone() or emergencyRig()
	character.Name = player.Name
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root, "Invalid fallback avatar")
	humanoid.Health, root.Anchored = humanoid.MaxHealth, false
	character:PivotTo(cf)
	-- Positioned before publishing: even the fallback never appears at an unrelated SpawnLocation.
	local oldCharacter = player.Character
	player.Character = character
	character.Parent = workspace
	if oldCharacter and oldCharacter ~= character then oldCharacter:Destroy() end
	return character
end
function Loader.load(player, state, config, current, cf)
	local done, success, failure = false, false, nil
	state.loading = true
	local thread = task.spawn(function()
		success, failure = pcall(function() player:LoadCharacterAsync() end)
		done = true
	end)
	state.loadThread = thread
	local untilTime = os.clock()+config.LoadTimeout
	while not done and current() and os.clock() < untilTime do task.wait(0.05) end
	if not done then pcall(task.cancel, thread) end
	if not current() then return nil end
	state.loading, state.loadThread = false, nil
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if done and success and char and char.Parent and hum and hum.Health > 0 then return char end
	warn("Phoenix avatar load failed; using cached/emergency rig", failure)
	return Loader.fallback(player, state, cf)
end
return Loader
