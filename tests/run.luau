-- Offline regression tests execute production modules with Lune Roblox datatypes.
-- World queries and services below are test doubles, NOT the Roblox physics engine.
local fs, luau, roblox = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox')
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local passed = 0
local function check(condition, name)
	assert(condition, name)
	passed += 1
	print('PASS ' .. name)
end
local function near(a, b) return (a-b).Magnitude < 0.0001 end
local function loadModule(path, extra)
	local env = {Vector3 = Vector3, CFrame = CFrame, Color3 = roblox.Color3, Enum = roblox.Enum,
		Instance = roblox.Instance, Vector2 = roblox.Vector2, UDim = roblox.UDim, UDim2 = roblox.UDim2,
		NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint, ColorSequence = roblox.ColorSequence}
	for k, v in extra or {} do env[k] = v end
	return luau.load(fs.readFile(path), {debugName = path, environment = env})()
end
local Math = loadModule('src/shared/Portal/Math.luau')
local Config = loadModule('src/shared/Portal/Config.luau')
local normals = {Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis, Vector3.new(1, 1, 0).Unit}
for i, normal in normals do
	local cf = Math.surfaceFrame(Vector3.new(4, 8, 12), normal)
	check(near(cf.ZVector, normal) and math.abs(cf.RightVector:Dot(cf.UpVector)) < 1e-6, 'surface frame ' .. i)
	local to = Math.surfaceFrame(Vector3.new(30, 14, -8), Vector3.zAxis)
	local map = Math.mapping(cf, to)
	check(near(map:VectorToWorldSpace(-normal*80), to.ZVector*80), 'incoming momentum exits outward ' .. i)
	local v = Vector3.new(18, -93, 7)
	check(math.abs(map:VectorToWorldSpace(v).Magnitude-v.Magnitude)<0.0001, 'speed preserved ' .. i)
	local point = Vector3.new(14, 4, 21)
	check(near(Math.mapping(to, cf):PointToWorldSpace(map:PointToWorldSpace(point)), point), 'round trip coordinates ' .. i)
end
check(not Math.finiteVector(Vector3.new(0/0, 0, 0)), 'reject NaN')
check(not Math.finiteVector(Vector3.new(math.huge, 0, 0)), 'reject infinity')
check(not Math.finiteVector({X = 0, Y = 0, Z = 0}), 'reject forged vector table')
check(Math.inEllipse(0, 0, 2, 4) and not Math.inEllipse(2, 4, 2, 4), 'oval corners excluded')
check(math.abs(Math.support(CFrame.Angles(0, 0, math.pi/2), Vector3.new(2, 6, 2), Vector3.xAxis)-3)<0.001, 'rotated avatar support extent')

-- Analytic ray/box intersection for placement edge tests.
local wall = {Size = Vector3.new(30, 30, 2), CFrame = CFrame.new(0, 10, 0), Anchored = true, CanCollide = true, Transparency = 0, Shape = roblox.Enum.PartType.Block}
function wall:IsA(class) return class == 'Part' end
function wall:GetAttribute() return self.allowed end
local obstructed, cameraBlocked = false, false
local world = {}
function world:Raycast(origin, direction)
	if cameraBlocked and direction.Magnitude < 2 then return {Position = origin, Instance = wall, Normal = Vector3.zAxis} end
	local o, d = wall.CFrame:PointToObjectSpace(origin), wall.CFrame:VectorToObjectSpace(direction)
	local lo, hi, normal = 0, 1, Vector3.zero
	for _, axis in {'X', 'Y', 'Z'} do
		local half = wall.Size[axis]/2
		if math.abs(d[axis]) < 1e-7 then
			if math.abs(o[axis]) > half then return nil end
		else
			local a, b = (-half-o[axis])/d[axis], (half-o[axis])/d[axis]
			local sign = -1
			if a > b then a, b, sign = b, a, 1 end
			if a > lo then
				lo = a
				normal = Vector3.new(axis == 'X' and sign or 0, axis == 'Y' and sign or 0, axis == 'Z' and sign or 0)
			end
			hi = math.min(hi, b)
			if lo > hi then return nil end
		end
	end
	return {Instance = wall, Position = origin+direction*lo, Normal = wall.CFrame:VectorToWorldSpace(normal)}
end
function world:GetPartBoundsInBox() return obstructed and {wall} or {} end
local root, head = {Position = Vector3.new(0, 10, 20)}, {Position = Vector3.new(0, 10, 20)}
local character = {}
function character:FindFirstChild(name) return name == 'Head' and head or root end
local shared = {Config = Config, Math = Math}
local Placement = loadModule('src/server/Portal/Placement.luau', {
	game = {GetService = function() return {Shared = {Portal = shared}} end},
	require = function(value) return value end,
	workspace = world, RaycastParams = {new = function() return {} end}, OverlapParams = {new = function() return {} end},
})
local function place(aim, existing, ignore) return Placement.validate(character, head.Position, (aim-head.Position).Unit, existing or {}, ignore) end
local portal = place(Vector3.new(0, 10, 1))
check(portal ~= nil, 'large flat wall accepted')
check(place(Vector3.new(14, 10, 1)) == nil, 'wall edge rejected')
wall.Size = Vector3.new(3, 3, 2)
check(place(Vector3.new(0, 10, 1)) == nil, 'tiny surface rejected')
wall.Size = Vector3.new(30, 30, 2)
wall.Anchored = false
check(place(Vector3.new(0, 10, 1)) == nil, 'moving surface rejected')
wall.Anchored, wall.allowed = true, false
check(place(Vector3.new(0, 10, 1)) == nil, 'opt-out surface rejected')
wall.allowed, obstructed = nil, true
check(place(Vector3.new(0, 10, 1)) == nil, 'blocked exit volume rejected')
obstructed = false
check(place(Vector3.new(0, 10, 1), {other = portal}) == nil, 'overlapping portals rejected')
check(place(Vector3.new(0, 10, 1), {same = portal}, 'same') ~= nil, 'own replacement may reuse its footprint')
check(Placement.validate(character, head.Position + Vector3.xAxis*50, -Vector3.zAxis, {}) == nil, 'forged camera origin rejected')
check(Placement.validate(character, head.Position, Vector3.zero, {}) == nil, 'zero direction rejected')
check(Placement.validate(character, head.Position, -Vector3.zAxis*100, {}) == nil, 'nonunit direction rejected')
check(place(Vector3.new(0, 10, 200)) == nil, 'miss rejected')
cameraBlocked = true
check(Placement.validate(character, head.Position+Vector3.xAxis, -Vector3.zAxis, {}) == nil, 'camera through wall rejected')
cameraBlocked = false
head.Position, root.Position = Vector3.new(0, 10, 250), Vector3.new(0, 10, 250)
check(place(Vector3.new(0, 10, 1)) == nil, 'excess range rejected')

-- Exercise real Service scheduling, alternation, replacement, and lifecycle.
local function signal()
	local s = {callbacks = {}}
	function s:Connect(callback) table.insert(self.callbacks, callback) end
	function s:fire(...) for _, callback in self.callbacks do callback(...) end end
	return s
end
local player = {UserId = 10, CharacterAdded = signal(), CharacterRemoving = signal()}
local player2 = {UserId = 20, CharacterAdded = signal(), CharacterRemoving = signal()}
local players = {PlayerAdded = signal(), PlayerRemoving = signal()}
function players:GetPlayers() return {player, player2} end
local heartbeat = signal()
local messages, jobs, now, valid = {}, {}, 0, true
local remote = {OnServerEvent = signal()}
function remote:FireAllClients(action, data) table.insert(messages, {action = action, data = data}) end
function remote:FireClient(who, action, data) table.insert(messages, {action = action, data = data, who = who}) end
local function flush() local queue = jobs; jobs = {}; for _, callback in queue do callback() end end
local stubPlacement = {
	rayParams = function() return {} end,
	validate = function()
		return valid and {cf = CFrame.new(0, 10, 1), surface = wall, surfaceCF = wall.CFrame, surfaceSize = wall.Size} or nil, 'Rejected', Vector3.new(0, 10, 1)
	end,
}
local services = {Players = players, RunService = {Heartbeat = heartbeat}, ReplicatedStorage = {Shared = {Portal = {Config = Config, Gun = {}}}}}
local service = loadModule('src/server/Portal/Service.luau', {
	game = {GetService = function(_, name) return services[name] end},
	script = {Parent = {Placement = stubPlacement, Transit = {new = function() return {forget = function() end, step = function() end} end}}},
	require = function(value) return value end,
	workspace = {Raycast = function() return nil end, GetServerTimeNow = function() return now end},
	os = {clock = function() return now end}, task = {delay = function(_, f) table.insert(jobs, f) end, spawn = function(f, ...) f(...) end},
})
service.start(remote)
local gun = {IsA = function() return true end, GetAttribute = function() return true end, FindFirstChild = function() return {MuzzleAttachment = {WorldPosition = Vector3.new(0, 10, 15)}} end}
local char = {Parent = true, FindFirstChildOfClass = function() return {Health = 100} end, FindFirstChild = function() return gun end}
player.Character, player2.Character = char, char
local function fire(who)
	now += 1
	remote.OnServerEvent:fire(who, 'Fire', Vector3.new(0, 10, 20), -Vector3.zAxis)
end
local function opens()
	local list = {}
	for _, m in messages do if m.action == 'Open' then table.insert(list, m.data) end end
	return list
end
fire(player)
check(#opens() == 0, 'portal waits for projectile impact')
remote.OnServerEvent:fire(player, 'Fire', Vector3.zero, -Vector3.zAxis)
check(#jobs == 1, 'spam cannot schedule concurrent shots')
flush()
check(opens()[1].slot == 'A', 'first success is A')
valid = false; fire(player); flush()
check(#opens() == 1, 'invalid hit creates no portal')
valid = true
fire(player); flush(); fire(player); flush(); fire(player); flush(); fire(player); flush()
local sequence = ''
for _, p in opens() do sequence ..= p.slot end
check(sequence == 'ABABA', 'valid placements alternate ABABA across a rejection')
local closes = 0
for _, m in messages do if m.action == 'Close' then closes += 1 end end
check(closes == 3, 'each replacement closes exactly the old slot')
fire(player2); flush()
check(opens()[6].key == '20:A', 'second player has independent A/B state')
now += 3; remote.OnServerEvent:fire(player, 'Sync')
local snapshot = messages[#messages]
check(snapshot.action == 'Snapshot' and #snapshot.data.portals == 3, 'late-join snapshot includes all active portals')
fire(player)
player.CharacterRemoving:fire()
flush()
check(#opens() == 6, 'respawn invalidates pending projectile callback')
fire(player); flush()
check(opens()[7].slot == 'A', 'respawn resets next slot to A')
players.PlayerRemoving:fire(player)
now += 3; remote.OnServerEvent:fire(player2, 'Sync')
check(#messages[#messages].data.portals == 1, 'disconnect removes both owned portals')
-- Reflection smoke checks exercise real model construction and renderer lifecycle.
local Gun = loadModule('src/shared/Portal/Gun.luau', {script = {Parent = {Config = Config}}, require = function(v) return v end})
local builtGun = Gun.create()
check(builtGun:FindFirstChild('Handle') ~= nil and builtGun.Muzzle:FindFirstChild('MuzzleAttachment') ~= nil, 'gun constructs with handle and muzzle')
local chamberWorld = roblox.Instance.new('Workspace')
local Chamber = loadModule('src/server/Portal/Chamber.luau', {workspace = chamberWorld})
Chamber.build(); Chamber.build()
check(#chamberWorld:GetChildren() == 1 and chamberWorld['Portal Test Chamber']:FindFirstChild('Lab spawn') ~= nil, 'chamber constructs once with spawn')
local fakeGame = {GetService = function(_, name)
	return name == 'ReplicatedStorage' and {Shared = {Portal = {Config = Config}}} or {}
end}
local Effects = loadModule('src/client/Portal/Effects.luau', {game = fakeGame, require = function(v) return v end})
local effectFolder = roblox.Instance.new('Folder')
local Renderer = loadModule('src/client/Portal/Renderer.luau', {
	game = fakeGame, require = function(v) return v end, script = {Parent = {Effects = Effects}},
	os = {clock = function() return now end}, workspace = {CurrentCamera = {CFrame = CFrame.new()}},
})
local effects = {folder = effectFolder, near = function() return true end, sound = function() end}
local renderer = Renderer.new(effects, {emit = function() end})
for i = 1, Config.MaxVisiblePortals+1 do renderer:make({key = tostring(i), cf = CFrame.new(i, 0, 0), slot = 'A'}, true) end
check(#effectFolder:GetChildren() == Config.MaxVisiblePortals, 'visible portal geometry budget enforced')
local portalModel = renderer.portals['1']
local partCount = 0
for _, part in portalModel.model:GetChildren() do if part:IsA('BasePart') then partCount += 1 end end
check(partCount == 78, 'portal geometry matches documented part budget')
local stretchable = true
for _, part in portalModel.model:GetChildren() do
	if part:IsA('BasePart') then
		local mesh = part:FindFirstChild('FluidShape')
		stretchable = stretchable and part.Shape ~= roblox.Enum.PartType.Ball
			and mesh ~= nil and mesh.MeshType == roblox.Enum.MeshType.Sphere and mesh.Scale == Vector3.one
	end
end
check(stretchable, 'every thin portal surface uses a stretchable sphere mesh, not a Ball Part')
check(portalModel.core.Size.X > 6 and portalModel.core.Size.Y > 9 and portalModel.core.Transparency == 0,
	'open portal has a full-size opaque green backing')
local beforeSwirl = portalModel.ribbons[6].part.CFrame
renderer:animate(portalModel, now+0.4)
check(portalModel.ribbons[6].part.CFrame ~= beforeSwirl, 'filled portal still animates its swirls')
renderer:close('1', false)
now += Config.CloseTime * 0.5
renderer:animate(portalModel, now)
check(portalModel.core.Size.X < Config.Width * 0.5, 'closing animation contracts the portal')
now += Config.CloseTime
renderer:step(1/30)
check(#renderer.closing == 0, 'finished collapse removes closing record and model')
renderer:reset()
check(#effectFolder:GetChildren() == 0 and next(renderer.known) == nil, 'renderer reset releases all active geometry and descriptors')
print(string.format('\n%d regression checks passed. Engine physics and visuals still require Studio.', passed))
