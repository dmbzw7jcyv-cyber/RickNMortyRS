local Shared = game:GetService("ReplicatedStorage").Shared.Portal
local Config, Math = require(Shared.Config), require(Shared.Math)
local Placement = {}
function Placement.rayParams(character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and {character} or {}
	params.RespectCanCollide = true
	return params
end
function Placement.validate(character, origin, direction, existing, ignoreKey)
	local head = character:FindFirstChild("Head")
	if not head or not Math.finiteVector(origin) or not Math.finiteVector(direction) then return nil, "Bad aim" end
	if (origin - head.Position).Magnitude > 18 or direction.Magnitude < 0.9 or direction.Magnitude > 1.1 then
		return nil, "Aim out of range"
	end
	local params = Placement.rayParams(character)
	-- Third-person cameras may not shoot through intervening walls.
	if (origin-head.Position).Magnitude > 0.1 and workspace:Raycast(head.Position, origin-head.Position, params) then
		return nil, "Camera is behind a wall"
	end
	local hit = workspace:Raycast(origin, direction.Unit * Config.Range, params)
	if not hit then return nil, "No surface in range", origin + direction.Unit * Config.Range end
	local surface, normal = hit.Instance, hit.Normal
	local cf = Math.surfaceFrame(hit.Position + normal * 0.06, normal)
	if not surface:IsA("Part") or surface.Shape ~= Enum.PartType.Block or not surface.Anchored
		or not surface.CanCollide or surface.Transparency > 0.5 or surface:GetAttribute("PortalSurface") == false then
		return nil, "Use an anchored flat wall or floor", hit.Position
	end
	if normal.Y < -0.5 then return nil, "Ceiling portals are disabled", hit.Position end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or (hit.Position - root.Position).Magnitude > Config.Range then return nil, "Too far", hit.Position end
	-- A full rectangular grid conservatively bounds the oval, catches edges, and rejects seams.
	for ix = -2, 2 do
		for iy = -3, 3 do
			local sample = cf:PointToWorldSpace(Vector3.new(ix * (Config.Width/2 + 0.2)/2, iy * (Config.Height/2 + 0.2)/3, 0))
			local check = workspace:Raycast(sample + normal * 0.5, -normal * 1, params)
			if not check or check.Instance ~= surface or check.Normal:Dot(normal) < 0.995
				or math.abs((check.Position-hit.Position):Dot(normal)) > 0.12 then
				return nil, "Portal does not fit on this face", hit.Position
			end
		end
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = {character, surface}
	overlap.RespectCanCollide = true
	if #workspace:GetPartBoundsInBox(cf * CFrame.new(0, 0, 2.5), Vector3.new(Config.Width + 0.2, Config.Height + 0.2, 4.8), overlap) > 0 then
		return nil, "Space in front of portal is obstructed", hit.Position
	end
	for key, portal in existing do
		if key ~= ignoreKey then
			local p = portal.cf:PointToObjectSpace(cf.Position)
			if math.abs(p.Z) < 1 and math.abs(portal.cf.ZVector:Dot(normal)) > 0.95
				and math.abs(p.X) < Config.Width + 0.5 and math.abs(p.Y) < Config.Height + 0.5 then
				return nil, "Too close to another portal", hit.Position
			end
		end
	end
	return {cf = cf, surface = surface, surfaceCF = surface.CFrame, surfaceSize = surface.Size}, nil, hit.Position
end
return Placement
