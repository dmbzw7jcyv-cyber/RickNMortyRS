local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config, Math = require(Shared.Config), require(Shared.Math)
local Transit = {}
Transit.__index = Transit
function Transit.new(remote)
	return setmetatable({remote = remote, tracks = {}, ownership = {}}, Transit)
end
function Transit:forget(player)
	self.tracks[player] = nil
	self.ownership[player] = nil
end
function Transit:step(dt, portals)
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or root.Anchored then
			self.tracks[player] = nil
			continue
		end
		local track = self.tracks[player]
		if not track or track.root ~= root then
			track = {root = root, previous = root.Position, lockedUntil = 0, exitKey = nil}
			self.tracks[player] = track
		end
		local velocity = root.AssemblyLinearVelocity
		local size = Vector3.new(math.max(3, root.Size.X + 1), math.max(5, humanoid.HipHeight * 2 + root.Size.Y), math.max(2, root.Size.Z + 1))
		if track.exitKey then
			local exit = portals[track.exitKey]
			if not exit or exit.cf:PointToObjectSpace(root.Position).Z > Math.support(root.CFrame, size, exit.cf.ZVector) + 2 then
				track.exitKey = nil
			end
		end
		if now >= track.lockedUntil then
			for key, source in portals do
				local destination = portals[source.pairKey]
				if not destination or key == track.exitKey or now < source.readyAt or now < destination.readyAt then continue end
				local localPosition = source.cf:PointToObjectSpace(root.Position)
				local before = source.cf:PointToObjectSpace(track.previous)
				local normal = source.cf.ZVector
				local approach = velocity:Dot(normal)
				local depth = Math.support(root.CFrame, size, normal) + 0.35
				local predicted = localPosition + source.cf:VectorToObjectSpace(velocity) * math.min(dt, 1/30)
				local crosses = before.Z > depth and localPosition.Z <= depth
				local near = localPosition.Z >= depth - 0.65 and predicted.Z <= depth
				if approach >= -0.5 or localPosition.Z < -0.2 or not (crosses or near) then continue end
				-- Interpolate lateral position at the capture plane, including fast diagonal motion.
				local start, finish = crosses and before or localPosition, crosses and localPosition or predicted
				local fraction = math.clamp((start.Z - depth) / math.max(start.Z - finish.Z, 0.001), 0, 1)
				local crossing = start:Lerp(finish, fraction)
				local rx = Config.Width/2 - Math.support(root.CFrame, size, source.cf.RightVector) * 0.65
				local ry = Config.Height/2 - Math.support(root.CFrame, size, source.cf.UpVector) * 0.65
				if not Math.inEllipse(crossing.X, crossing.Y, rx, ry) then continue end
				local map = Math.mapping(source.cf, destination.cf)
				local rotation = map.Rotation * root.CFrame.Rotation
				local exitDepth = Math.support(rotation, size, destination.cf.ZVector) + 0.65
				local target = CFrame.new(destination.cf:PointToWorldSpace(Vector3.new(-crossing.X, crossing.Y, exitDepth))) * rotation
				local overlap = OverlapParams.new()
				overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
				overlap.RespectCanCollide = true
				if #workspace:GetPartBoundsInBox(target, size - Vector3.one * 0.12, overlap) > 0 then
					track.lockedUntil = now + 0.2
					self.remote:FireClient(player, "Status", {message = "Portal exit blocked — clear the landing area"})
					break
				end
				local outgoing = map:VectorToWorldSpace(velocity)
				if outgoing.Magnitude > Config.MaxTransitSpeed then outgoing = outgoing.Unit * Config.MaxTransitSpeed end
				local spin = map:VectorToWorldSpace(root.AssemblyAngularVelocity)
				local canOwn = root:CanSetNetworkOwnership()
				if canOwn then root:SetNetworkOwner(nil) end
				character:PivotTo(target * root.CFrame:Inverse() * character:GetPivot())
				root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = outgoing, spin
				if outgoing.Y > 5 then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
				track.lockedUntil, track.exitKey = now + Config.ExitLock, destination.key
				local token = {}
				self.ownership[player] = token
				task.delay(0.2, function()
					if self.ownership[player] ~= token then return end
					self.ownership[player] = nil
					if root.Parent and root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto() end
				end)
				self.remote:FireAllClients("Transit", {source = source.cf, destination = destination.cf, userId = player.UserId, rotation = map.Rotation})
				break
			end
		end
		track.previous = root.Position
	end
end
return Transit
