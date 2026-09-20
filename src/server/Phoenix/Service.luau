local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared.Phoenix
local Config, Policy, Sequences = require(Shared.Config), require(Shared.Policy), require(Shared.Sequences)
local Body, Chamber, Loader = require(script.Parent.Body), require(script.Parent.Chamber), require(script.Parent.AvatarLoader)
local Service = {}
function Service.start(remote, lab)
	local states = {}
	local begin
	local function packet(player, state, phase, duration, hit)
		return {userId = player.UserId, token = state.token, chamberId = state.slot.id, cf = state.slot.cf,
			phase = phase, duration = duration, hit = hit, variation = state.variation, startedAt = workspace:GetServerTimeNow()}
	end
	local function stage(player, state, phase, duration, hit)
		state.packet = packet(player, state, phase, duration, hit)
		player:SetAttribute("PhoenixPhase", phase)
		Chamber.stage(state.slot, phase, duration, hit)
		remote:FireAllClients("Stage", state.packet)
	end
	local function cancelWork(state)
		for _, key in {"loadThread", "runThread"} do
			local thread = state[key]
			if thread and thread ~= coroutine.running() then pcall(task.cancel, thread) end
			state[key] = nil
		end
		state.loading = false
	end
	local function healthy(player)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return char and char.Parent and hum and hum.Health > 0
	end
	local function finish(player, state, emergency)
		Body.restore(state.body); state.body = nil
		state.active = false
		player:SetAttribute("PhoenixActive", false)
		player:SetAttribute("PhoenixPhase", "Alive")
		player.RespawnLocation = state.originalSpawn and state.originalSpawn.Parent and state.originalSpawn or lab.safe
		if emergency and healthy(player) then player.Character:PivotTo(lab.safe.CFrame*CFrame.new(0, 4, 0)) end
		remote:FireClient(player, "End", {token = state.token})
		if healthy(player) then Loader.cache(state, player.Character) end
	end
	local function recover(player, state, reason)
		if states[player] ~= state or state.left then return end
		warn("Phoenix recovery for " .. player.Name .. ": " .. tostring(reason))
		state.token += 1 -- Invalidates every delayed callback belonging to the failed generation.
		cancelWork(state)
		Body.restore(state.body); state.body = nil
		state.active = false
		Chamber.reset(state.slot)
		if not healthy(player) then
			local ok, failure = pcall(Loader.fallback, player, state, lab.safe.CFrame*CFrame.new(0, 4, 0))
			if not ok then warn("Phoenix fallback failed", failure); state.retryAt = os.clock()+Config.RetryDelay end
		end
		finish(player, state, true)
	end
	local function waitFor(state, current, seconds)
		local ends = os.clock()+seconds
		while current() and os.clock() < ends do task.wait(math.min(0.05, math.max(0, ends-os.clock()))) end
		return current()
	end
	begin = function(player, state)
		if states[player] ~= state or state.left then return end
		state.token += 1
		cancelWork(state)
		Body.restore(state.body); state.body = nil
		Chamber.reset(state.slot)
		state.active, state.deadline = true, os.clock()+Config.SequenceTimeout
		state.variation = Policy.choose(Config, math.random())
		player:SetAttribute("PhoenixActive", true)
		local token = state.token
		local function current() return Policy.current(states, player, state, token) end
		stage(player, state, "Transfer", Config.TransferTime)
		state.runThread = task.spawn(function()
			local ok, failure = xpcall(function()
				if not waitFor(state, current, Config.TransferTime) then return end
				stage(player, state, "Activate", 0.7)
				-- The engine itself spawns at the reserved tank. CharacterAdded hides/anchors
				-- the body before Workspace parenting; no normal-spawn-then-teleport trick.
				player.RespawnLocation = state.slot.spawn
				local char = Loader.load(player, state, Config, current, state.slot.cf*CFrame.new(0, 6, 0))
				if not current() or not char then return end
				assert(state.body and state.body.character == char, "Phoenix body lock missing")
				state.body.root.Anchored = true
				Body.position(state.body, state.slot)
				-- Keep the reserve body visible while loading, then exchange it for the
				-- living avatar without a reconstruction fade or extra cinematic stage.
				Body.reveal(state.body, 0)
				for _, step in Sequences[state.variation] do
					if not current() then return end
					stage(player, state, step.name, step.duration, step.hit)
					if step.name == "Exit" then
						local body = state.body
						local legs = body.humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or body.humanoid.HipHeight
						local target = state.slot.cf*CFrame.new(0, 1+legs+body.root.Size.Y/2+0.1, -7.5)
						Chamber.tween(state.slot, body.root, step.duration, {CFrame = target})
					end
					if not waitFor(state, current, step.duration) then return end
				end
				finish(player, state, false)
				local damaged = state.variation == "Breakout"
				stage(player, state, damaged and "Damaged" or "Cooldown", damaged and Config.DamagedCooldown or Config.NormalCooldown)
				local revision = state.slot.revision
				task.delay(damaged and Config.DamagedCooldown or Config.NormalCooldown, function()
					if current() and state.slot.revision == revision then
						Chamber.reset(state.slot)
						remote:FireAllClients("Reset", {chamberId = state.slot.id, token = token})
					end
				end)
			end, debug.traceback)
			if not ok and current() then recover(player, state, failure) end
		end)
	end
	local function added(player)
		local slot = Policy.reserve(lab.slots, player.UserId, function(index) return lab:create(index) end)
		local original = player.RespawnLocation
		if not original then
			local portalLab = workspace:FindFirstChild("Portal Test Chamber")
			original = portalLab and portalLab:FindFirstChild("Lab spawn") or lab.safe
		end
		local state = {slot = slot, originalSpawn = original, token = 0, active = false, connections = {}, lastSync = -math.huge}
		states[player] = state
		Chamber.reset(slot)
		player.RespawnLocation = original
		local function characterAdded(character)
			if state.left then return end
			if state.deathConnection then state.deathConnection:Disconnect() end
			Body.restore(state.body); state.body = nil
			state.character = character
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then recover(player, state, "Character missing Humanoid"); return end
			state.deathConnection = humanoid.Died:Connect(function()
				if player.Character == character then begin(player, state) end
			end)
			if state.active then
				local ok, result = pcall(Body.lock, character)
				if ok then state.body = result; Body.position(state.body, slot)
				else task.defer(recover, player, state, result) end
			end
		end
		table.insert(state.connections, player.CharacterAdded:Connect(characterAdded))
		table.insert(state.connections, player.CharacterAppearanceLoaded:Connect(function(character)
			if not state.active and player.Character == character then Loader.cache(state, character) end
		end))
		table.insert(state.connections, player.CharacterRemoving:Connect(function(character)
			if state.loading or state.active then return end
			task.delay(0.2, function()
				if states[player] == state and not state.active and not state.loading and not healthy(player) then
					recover(player, state, "Character removed outside normal death flow")
				end
			end)
		end))
		if player.Character then characterAdded(player.Character) end
		if not healthy(player) then
			state.runThread = task.spawn(function()
				local token = state.token
				local function current() return Policy.current(states, player, state, token) end
				local ok, failure = pcall(Loader.load, player, state, Config, current, lab.safe.CFrame*CFrame.new(0, 4, 0))
				if not ok and current() then recover(player, state, failure)
				elseif current() and healthy(player) then Loader.cache(state, player.Character) end
			end)
		end
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		if not state then return end
		state.left = true
		cancelWork(state)
		Body.restore(state.body)
		for _, connection in state.connections do connection:Disconnect() end
		if state.deathConnection then state.deathConnection:Disconnect() end
		if state.template then state.template:Destroy() end
		Chamber.reset(state.slot)
		remote:FireAllClients("Reset", {chamberId = state.slot.id, token = state.token})
		state.slot.owner, states[player] = nil, nil
	end)
	for _, player in Players:GetPlayers() do added(player) end
	remote.OnServerEvent:Connect(function(player, action)
		local state = states[player]
		if action ~= "Sync" or not state or os.clock()-state.lastSync < 2 then return end
		state.lastSync = os.clock()
		if state.active and state.packet then remote:FireClient(player, "Stage", state.packet)
		else remote:FireClient(player, "End", {token = state.token}) end
	end)
	-- Low-frequency watchdog is independent of sequence coroutines and client acknowledgements.
	task.spawn(function()
		while remote.Parent do
			task.wait(0.5)
			for player, state in states do
				if state.active and os.clock() > state.deadline then recover(player, state, "Sequence deadline exceeded")
				elseif state.retryAt and os.clock() > state.retryAt then state.retryAt = nil; recover(player, state, "Retrying emergency spawn") end
			end
		end
	end)
end
return Service
