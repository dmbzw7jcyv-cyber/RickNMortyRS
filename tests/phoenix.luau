-- Executes production Phoenix policy/controller with a deterministic scheduler and service doubles.
-- This checks lifecycle decisions, NOT Roblox engine spawning, physics, animation or rendering.
local fs, luau, r = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox')
local function loadModule(path, extra)
	local env = {Vector2 = r.Vector2, Vector3 = r.Vector3, CFrame = r.CFrame, Color3 = r.Color3, Enum = r.Enum, Instance = r.Instance,
		UDim2 = r.UDim2, ColorSequence = r.ColorSequence, NumberSequence = r.NumberSequence, NumberRange = r.NumberRange}
	for k, v in extra or {} do env[k] = v end
	return luau.load(fs.readFile(path), {debugName = path, environment = env})()
end
local passed = 0
local function check(condition, name) assert(condition, name); passed += 1; print('PASS Phoenix: '..name) end
local config = loadModule('src/shared/Phoenix/Config.luau')
local policy = loadModule('src/shared/Phoenix/Policy.luau')
local sequences = loadModule('src/shared/Phoenix/Sequences.luau')
config.Debug.ForceExitVariation = 'Normal'
check(policy.choose(config, 0.9) == 'Normal', 'forced Normal')
config.Debug.ForceExitVariation = 'Breakout'
check(policy.choose(config, 0.1) == 'Breakout', 'forced Breakout')
config.Debug.ForceExitVariation = nil
check(policy.choose(config, 0.1) == 'Normal' and policy.choose(config, 0.9) == 'Breakout', 'nil mode uses weights')
config.Debug.ForceExitVariation = 'Random'
check(policy.choose(config, 0.49) == 'Normal' and policy.choose(config, 0.5) == 'Breakout', 'Random threshold')
local function signal()
	local s = {callbacks = {}}
	function s:Connect(fn)
		local c = {fn = fn, live = true}
		function c:Disconnect() self.live = false end
		table.insert(self.callbacks, c); return c
	end
	function s:fire(...)
		local list = table.clone(self.callbacks)
		for _, c in list do if c.live then c.fn(...) end end
	end
	return s
end
local now, queue, cancelled = 0, {}, {}
local function schedule(thread, at) table.insert(queue, {thread = thread, at = at}) end
local tasks = {}
function tasks.spawn(fn, ...)
	local args = table.pack(...)
	local thread = coroutine.create(function() fn(table.unpack(args, 1, args.n)) end)
	schedule(thread, now); return thread
end
function tasks.delay(duration, fn, ...)
	local thread = tasks.spawn(fn, ...)
	queue[#queue].at = now+duration; return thread
end
function tasks.defer(fn, ...) return tasks.delay(0.001, fn, ...) end
function tasks.wait(duration) return coroutine.yield(duration or 1/30) end
function tasks.cancel(thread) cancelled[thread] = true end
local function advance(seconds)
	local target, iterations = now+seconds, 0
	while true do
		table.sort(queue, function(a,b) return a.at < b.at end)
		local job = queue[1]
		if not job or job.at > target then break end
		table.remove(queue, 1)
		now = job.at
		if not cancelled[job.thread] then
			local ok, delay = coroutine.resume(job.thread)
			assert(ok, tostring(delay))
			if coroutine.status(job.thread) ~= 'dead' then schedule(job.thread, now+math.max(0.001, delay or 0.001)) end
		end
		iterations += 1; assert(iterations < 50000, 'scheduler did not converge')
	end
	now = target
end
local function player(id)
	local p = {UserId = id, Name = 'Tester'..id, CharacterAdded = signal(), CharacterRemoving = signal(), CharacterAppearanceLoaded = signal(), attrs = {}}
	function p:SetAttribute(key,value) self.attrs[key] = value end
	function p:GetAttribute(key) return self.attrs[key] end
	return p
end
local p1, p2 = player(1), player(2)
local players = {PlayerAdded = signal(), PlayerRemoving = signal(), list = {p1,p2}}
function players:GetPlayers() return self.list end
local function character(p)
	local hum = {Health = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2, AutoRotate = true, Died = signal(), HipHeight = 2, RigType = r.Enum.HumanoidRigType.R15}
	local root = {Size = r.Vector3.new(2,2,1), CFrame = r.CFrame.new(), Anchored = false}
	local char = {Parent = true, hum = hum, root = root, attrs = {}}
	function char:FindFirstChildOfClass() return hum end
	function char:FindFirstChild(name) return name == 'HumanoidRootPart' and root or nil end
	function char:SetAttribute(key,value) self.attrs[key] = value end
	function char:GetAttribute(key) return self.attrs[key] end
	function char:PivotTo(cf) self.root.CFrame = cf end
	function char:GetPivot() return self.root.CFrame end
	p.Character = char
	p.CharacterAdded:fire(char)
	return char
end
local model = {SetAttribute = function() end}
local function slot(index)
	return {id = index, model = model, cf = r.CFrame.new(index*22,0,136), floorY = 2.55, revision = 0, spawn = {Parent = true, isTank = true, id = index}}
end
local lab = {slots = {slot(1)}, safe = {Parent = true, CFrame = r.CFrame.new(0,1,90)}}
function lab:create(index) return slot(index) end
local events, loads, failPhase, hangLoad = {}, {}, nil, false
local remote = {Parent = true, OnServerEvent = signal()}
function remote:FireAllClients(action,data) table.insert(events,{action=action,data=data,time=now}) end
function remote:FireClient(p,action,data) table.insert(events,{action=action,data=data,player=p,time=now}) end
local chamber = {}
function chamber.reset(s) s.revision += 1; s.phase = 'Idle' end
function chamber.stage(s, phase)
	if phase == failPhase then error('injected stage failure') end
	s.phase = phase
end
function chamber.tween(_,object,_,properties) for key,value in properties do object[key] = value end end
local body = {}
function body.lock(char)
	char.root.Anchored, char.hum.WalkSpeed = true, 0
	char:SetAttribute('PhoenixBusy', true)
	return {character = char, root = char.root, humanoid = char.hum}
end
function body.position(b,s) b.root.CFrame = s.cf*r.CFrame.new(0,6,0) end
function body.reveal(b) b.character.revealed = true end
function body.restore(b)
	if b then b.root.Anchored, b.humanoid.WalkSpeed = false, 16; b.character:SetAttribute('PhoenixBusy',false) end
end
local loader = {}
function loader.cache() end
function loader.fallback(p,_,cf) local char = character(p); char:PivotTo(cf); return char end
function loader.load(p, state, _, current, cf)
	state.loading = true
	table.insert(loads, {player = p, spawn = p.RespawnLocation, active = state.active})
	if hangLoad and state.active then tasks.wait(100) end
	if not current() then return nil end
	local old = p.Character
	if old then p.CharacterRemoving:fire(old); old.Parent = nil end
	local char = character(p)
	if not state.active then char:PivotTo(cf) end
	state.loading = false
	return char
end
local shared = {Config=config,Policy=policy,Sequences=sequences}
local services = {Players=players,ReplicatedStorage={Shared={Phoenix=shared}}}
local Service = loadModule('src/server/Phoenix/Service.luau', {
	game={GetService=function(_,name) return services[name] end}, script={Parent={Body=body,Chamber=chamber,AvatarLoader=loader}},
	require=function(v) return v end, task=tasks, os={clock=function() return now end},
	workspace={GetServerTimeNow=function() return now end,FindFirstChild=function() return nil end}, warn=function() end,
})
Service.start(remote,lab); advance(0.1)
check(p1.Character and p2.Character, 'initial joins receive characters with manual autoload ownership')
check(#lab.slots == 2 and lab.slots[1].owner ~= lab.slots[2].owner, 'concurrent players reserve exclusive chambers; overflow grows')
local function die(p)
	p.Character.hum.Health = 0
	p.Character.hum.Died:fire()
end
local function phases(p, start)
	local list = {}
	for i = start or 1, #events do
		local e = events[i]
		if e.action == 'Stage' and e.data.userId == p.UserId then table.insert(list,e.data.phase) end
	end
	return table.concat(list, ',')
end
config.Debug.ForceExitVariation = 'Normal'
local start = #events+1
die(p1)
check(p1:GetAttribute('PhoenixActive') == true and phases(p1,start) == 'Transfer', 'real Died signal starts transfer immediately')
advance(0.6)
check(loads[#loads].spawn.isTank == true and loads[#loads].active, 'respawn target set to tank before avatar load')
check(p1.Character.root.Anchored and p1.Character.hum.WalkSpeed == 0, 'replacement body locked inside reconstruction')
advance(8)
check(phases(p1,start) == 'Transfer,Activate,Reconstruct,Wake,Drain,Unlock,Open,Exit,Cooldown', 'forced normal includes full death/reconstruction lifecycle')
check(not p1.Character.root.Anchored and p1.Character.hum.WalkSpeed == 16 and not p1:GetAttribute('PhoenixActive'), 'normal completion restores server control')
config.Debug.ForceExitVariation = 'Breakout'
start = #events+1
die(p1); advance(9)
check(phases(p1,start) == 'Transfer,Activate,Reconstruct,Wake,Pump,Malfunction,Pound,Pound,Pound,Burst,Exit,Damaged', 'forced breakout includes failure, three hits, burst and damaged cooldown')
check(not p1.Character.root.Anchored and p1.Character.revealed, 'breakout returns a visible unlocked replacement')
start = #events+1
die(p1); die(p2); advance(9)
check(phases(p1,start):find('Reconstruct') and phases(p2,start):find('Reconstruct'), 'simultaneous deaths both reconstruct')
check(not p1:GetAttribute('PhoenixActive') and not p2:GetAttribute('PhoenixActive'), 'simultaneous deaths both complete')
die(p1); advance(0.6)
local interrupted = p1.Character
die(p1); advance(9)
check(p1.Character ~= interrupted and not p1:GetAttribute('PhoenixActive'), 'death during reconstruction cancels old generation and resurrects again')
failPhase = 'Drain'; config.Debug.ForceExitVariation = 'Normal'
die(p1); advance(5)
check(not p1:GetAttribute('PhoenixActive') and not p1.Character.root.Anchored, 'exit exception recovers instead of freezing')
check(lab.slots[1].phase == 'Idle', 'failed chamber resets')
failPhase, hangLoad = nil, true
die(p1); advance(config.SequenceTimeout+1)
check(p1.Character.hum.Health > 0 and not p1:GetAttribute('PhoenixActive'), 'independent watchdog recovers stalled sequence')
hangLoad = false
start = #events
remote.OnServerEvent:fire(p2,'Complete')
remote.OnServerEvent:fire(p2,'Die')
check(#events == start and not p2:GetAttribute('PhoenixActive'), 'client cannot claim death or completion')
remote.OnServerEvent:fire(p2,'Sync')
local synced = #events
remote.OnServerEvent:fire(p2,'Sync')
check(#events == synced, 'read-only sync rate limited')
die(p2); advance(0.6)
players.PlayerRemoving:fire(p2); advance(10)
check(lab.slots[2].owner == nil and lab.slots[2].phase == 'Idle', 'disconnect releases chamber and cancels pending work')
local p3 = player(3); table.insert(players.list,p3); players.PlayerAdded:fire(p3); advance(0.1)
check(lab.slots[2].owner == 3 and #lab.slots == 2, 'released chamber reused without double occupancy')
-- Reflection smoke test: real chamber geometry, properties, reference-style glass and spawn.
local Model = loadModule('src/server/Phoenix/Model.luau', {game={GetService=function() return {Shared={Phoenix={Config=config}}} end},require=function(v) return v end})
local parent = r.Instance.new('Folder')
local chamberModel = Model.build(parent,1)
check(chamberModel.glass.Transparency > 0.5 and chamberModel.spawn.Transparency == 1, 'reference tube has transparent glass and hidden internal spawn')
check(chamberModel.spawn:GetAttribute('PortalSurface') == false, 'cloning hardware excludes portal placement')
check(chamberModel.model:FindFirstChild('Pump housing') and chamberModel.model:FindFirstChild('Relay box'), 'chamber includes asymmetric pump and relay equipment')
-- Exercise the actual body lock/reveal/restore code against reflection-backed instances.
local descendants = signal()
r.implementProperty('Instance', 'DescendantAdded', function() return descendants end)
r.implementMethod('Humanoid', 'UnequipTools', function() end)
local tweenService = {Create = function(_, object, _, props)
	return {Play = function() for key,value in props do object[key] = value end end, Cancel = function() end}
end}
local Body = loadModule('src/server/Phoenix/Body.luau', {
	game = {GetService = function() return tweenService end}, TweenInfo = {new = function() return {} end},
})
local rig = r.Instance.new('Model'); rig.Parent = parent
local hum = r.Instance.new('Humanoid'); hum.Parent = rig
hum.WalkSpeed, hum.JumpPower, hum.JumpHeight, hum.AutoRotate = 23, 61, 8.2, true
local root = r.Instance.new('Part'); root.Name, root.Transparency, root.Parent = 'HumanoidRootPart', 1, rig
local head = r.Instance.new('Part'); head.Name, head.Transparency, head.Parent = 'Head', 0.2, rig
local locked = Body.lock(rig)
check(root.Anchored and hum.WalkSpeed == 0 and head.Transparency == 1, 'production Body.lock anchors and hides the rig')
local accessory = r.Instance.new('Part'); accessory.Transparency, accessory.Parent = 0.35, rig
descendants:fire(accessory)
check(accessory.Transparency == 1, 'late avatar accessories hidden during reconstruction')
Body.reveal(locked,1)
check(math.abs(head.Transparency-0.2)<0.001 and math.abs(accessory.Transparency-0.35)<0.001, 'reveal preserves original per-part transparency')
Body.restore(locked)
check(not root.Anchored and hum.WalkSpeed == 23 and hum.JumpPower == 61 and math.abs(hum.JumpHeight-8.2)<0.001,
	'production restore returns original movement values')
check(root.Transparency == 1 and rig:FindFirstChild('PhoenixProtection') == nil and not rig:GetAttribute('PhoenixBusy'), 'restore clears shield/busy flag and keeps root invisible')
-- The production avatar loader gets a stalled engine call to exercise its bounded fallback.
-- Lune has datatypes but no engine Model:PivotTo implementation; emulate only this primitive.
r.implementMethod('Model', 'PivotTo', function(model, target)
	local root = model:FindFirstChild('HumanoidRootPart')
	local delta = target*root.CFrame:Inverse()
	for _, part in model:GetDescendants() do if part:IsA('BasePart') then part.CFrame = delta*part.CFrame end end
end)
local stagingWorld = r.Instance.new('Workspace')
local Loader = loadModule('src/server/Phoenix/AvatarLoader.luau', {
	game = {GetService = function() return {StarterCharacterScripts = r.Instance.new('Folder')} end},
	task = tasks, os = {clock = function() return now end}, workspace = stagingWorld, warn = function() end,
})
local cached = {}
rig.Archivable = false
Loader.cache(cached, rig)
check(cached.template ~= nil and rig.Archivable == false, 'avatar cache preserves source Archivable flag')
local stalledPlayer = {Name = 'Stalled', LoadCharacterAsync = function() tasks.wait(100) end}
local result
local startTime = now
tasks.spawn(function() result = Loader.load(stalledPlayer,cached,{LoadTimeout=0.2},function() return true end,r.CFrame.new(0,6,136)) end)
advance(0.4)
check(result ~= nil and result.Parent == stagingWorld and now-startTime < 1, 'actual avatar loader timeout publishes cached avatar promptly')
check(result:FindFirstChild('Head') ~= nil and cached.loading == false, 'cached fallback retains body and clears load lock')
local cancelledState = {}
local stillCurrent = true
tasks.spawn(function() result = Loader.load(stalledPlayer,cancelledState,{LoadTimeout=0.2},function() return stillCurrent end,r.CFrame.new()) end)
advance(0.05); stillCurrent = false; advance(0.2)
check(result == nil, 'superseded load generation does not publish a fallback')
-- Presentation regression checks: fluid reset/drain, reserve body safety and strike timing.
local realChamber = loadModule('src/server/Phoenix/Chamber.luau', {
 game = {GetService = function(_, service)
  if service == 'TweenService' then return tweenService end
  return {Shared={Phoenix={Config=config}}}
 end}, require=function(v) return v end, TweenInfo={new=function() return {} end},
})
realChamber.reset(chamberModel)
check(chamberModel.fluid.Size.X > 7 and chamberModel.fluid.Transparency < 0.5 and chamberModel.bubbles.Rate > 0, 'standby tank stays visibly filled and bubbling')
realChamber.fluid(chamberModel, 0, 1)
check(chamberModel.fluid.Size.X < 0.1 and chamberModel.surface.Transparency == 1 and chamberModel.bubbles.Rate == 0, 'drain lowers fluid and waterline and stops bubbles')
realChamber.reset(chamberModel)
check(chamberModel.surface.Transparency < 0.3, 'repair restores visible waterline')
local motion = loadModule('src/shared/Phoenix/Motion.luau')
check(motion.strike(0.3) < 0 and motion.strike(motion.Contact) == 1 and motion.strike(1) == 0, 'strike has wind-up, glass contact, recoil')
local final = motion.sample('Pound',1,0,3,'Breakout')
local burst = motion.sample('Burst',0,0,nil,'Breakout')
check(final.forward == burst.forward and final.shoulder == burst.shoulder, 'last fist remains against glass at shatter boundary')
local left = motion.sample('Pound',1,10,1,'Breakout')
local right = motion.sample('Pound',0,10,2,'Breakout')
check(left.shoulder == right.shoulder and left.bob == right.bob, 'consecutive strikes share a continuous resting pose and float clock')
r.implementMethod('Model', 'GetPivot', function(model) return model:FindFirstChild('HumanoidRootPart').CFrame end)
local storage = loadModule('src/server/Phoenix/Storage.luau', {game={GetService=function() return {} end}})
local unsafe = r.Instance.new('Script'); unsafe.Parent = rig
local tool = r.Instance.new('Tool'); tool.Parent = rig
storage.create(chamberModel, rig)
local copy = chamberModel.storedBody
check(copy and copy:FindFirstChildOfClass('Script') == nil and copy:FindFirstChildOfClass('Tool') == nil, 'stored avatar strips executable scripts and tools')
check(copy.HumanoidRootPart.Anchored and not copy.Head.CanTouch and not copy.Head.CanQuery and rig.Archivable == false, 'stored avatar cannot collide, trigger death pad, or intercept portal rays')
storage.clear(chamberModel)
check(chamberModel.storedBody == nil and copy.Parent == nil, 'stored body cleanup removes cosmetic copy')
print(string.format('\n%d Phoenix checks passed; live Studio engine checks remain required.', passed))
