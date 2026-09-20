local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config, Gun = require(Shared.Config), require(Shared.Gun)
local Placement, Transit = require(script.Parent.Placement), require(script.Parent.Transit)
local Service = {}
function Service.start(remote)
	local states, portals = {}, {}
	local transit = Transit.new(remote)
	local function remove(key)
		if portals[key] then
			portals[key] = nil
			remote:FireAllClients("Close", {key = key})
		end
	end
	local function reset(player)
		local old = states[player]
		states[player] = {nextSlot = "A", lastShot = -math.huge, lastSync = old and old.lastSync or -math.huge, busy = false, serial = 0}
		remove(tostring(player.UserId) .. ":A")
		remove(tostring(player.UserId) .. ":B")
		transit:forget(player)
	end
	local function spawn(player, character)
		reset(player)
		local backpack = player:WaitForChild("Backpack", 10)
		if not backpack or player.Character ~= character then return end
		for _, item in backpack:GetChildren() do
			if item:GetAttribute("PortalGun") then item:Destroy() end
		end
		Gun.create().Parent = backpack
	end
	local function added(player)
		reset(player)
		player.CharacterAdded:Connect(function(character) spawn(player, character) end)
		player.CharacterRemoving:Connect(function() reset(player) end)
		if player.Character then task.spawn(spawn, player, player.Character) end
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(player) reset(player); states[player] = nil end)
	for _, player in Players:GetPlayers() do added(player) end
	local function public(portal)
		return {key = portal.key, cf = portal.cf, owner = portal.owner, slot = portal.slot}
	end
	remote.OnServerEvent:Connect(function(player, action, origin, direction)
		local state = states[player]
		if not state then return end
		local now = os.clock()
		if action == "Sync" then
			if now - state.lastSync < 2 then return end
			state.lastSync = now
			local list = {}
			for _, portal in portals do table.insert(list, public(portal)) end
			remote:FireClient(player, "Snapshot", {portals = list, nextSlot = state.nextSlot})
			return
		end
		if action ~= "Fire" or now - state.lastShot < Config.ShotCooldown or state.busy then return end
		state.lastShot = now -- Invalid traffic consumes rate limit too.
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local tool = character and character:FindFirstChild("Portal Gun")
		if not humanoid or humanoid.Health <= 0 or character:GetAttribute("PhoenixBusy") or not tool or not tool:IsA("Tool") or not tool:GetAttribute("PortalGun") then return end
		local muzzle = tool:FindFirstChild("Muzzle")
		if not muzzle then return end
		local key = tostring(player.UserId) .. ":" .. state.nextSlot
		local candidate, reason, hitPoint = Placement.validate(character, origin, direction, portals, key)
		if not hitPoint then
			remote:FireClient(player, "Status", {message = reason or "Invalid shot"})
			return
		end
		local muzzlePosition = muzzle.MuzzleAttachment.WorldPosition
		-- A camera can see around a corner while the physical gun cannot.
		local barrelHit = workspace:Raycast(muzzlePosition, hitPoint - muzzlePosition, Placement.rayParams(character))
		if barrelHit and (barrelHit.Position - hitPoint).Magnitude > 0.4 then
			candidate, reason, hitPoint = nil, "Gun muzzle is obstructed", barrelHit.Position
		end
		local duration = math.clamp((hitPoint - muzzlePosition).Magnitude / Config.ProjectileSpeed, 0.08, 0.9)
		state.busy, state.serial = true, state.serial + 1
		local serial = state.serial
		remote:FireAllClients("Shot", {from = muzzlePosition, to = hitPoint, duration = duration, startedAt = workspace:GetServerTimeNow(), userId = player.UserId})
		task.delay(duration, function()
			if states[player] ~= state or player.Character ~= character or not character.Parent or humanoid.Health <= 0 then return end
			if state.serial ~= serial then return end
			state.busy = false
			-- Re-check geometry, portal overlap, and player position at impact, never trust stale validation.
			if candidate then
				local fresh, newReason = Placement.validate(character, origin, direction, portals, key)
				if not fresh or fresh.surface ~= candidate.surface or (fresh.cf.Position - candidate.cf.Position).Magnitude > 0.15 then
					candidate, reason = nil, newReason or "Surface moved before impact"
				else candidate = fresh end
			end
			if not candidate then
				remote:FireAllClients("Impact", {position = hitPoint, valid = false})
				remote:FireClient(player, "Status", {message = reason or "Placement rejected", nextSlot = state.nextSlot})
				return
			end
			remove(key)
			candidate.key, candidate.owner, candidate.slot = key, player.UserId, state.nextSlot
			candidate.pairKey = tostring(player.UserId) .. ":" .. (state.nextSlot == "A" and "B" or "A")
			candidate.readyAt = os.clock() + Config.OpenTime
			portals[key] = candidate
			state.nextSlot = state.nextSlot == "A" and "B" or "A"
			remote:FireAllClients("Impact", {position = hitPoint, valid = true})
			remote:FireAllClients("Open", public(candidate))
			remote:FireClient(player, "Status", {message = "Portal " .. candidate.slot .. " placed", nextSlot = state.nextSlot})
		end)
	end)
	RunService.Heartbeat:Connect(function(dt)
		for key, portal in portals do
			if not portal.surface:IsDescendantOf(workspace) or not portal.surface.Anchored or not portal.surface.CanCollide
				or portal.surface:GetAttribute("PortalSurface") == false or portal.surface.CFrame ~= portal.surfaceCF or portal.surface.Size ~= portal.surfaceSize then remove(key) end
		end
		transit:step(dt, portals)
	end)
end
return Service
