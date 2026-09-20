local fs,luau,r=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox')
local function load(path,extra)
 local env={Vector3=r.Vector3,Vector2=r.Vector2,CFrame=r.CFrame,Color3=r.Color3,UDim2=r.UDim2,UDim=r.UDim,Enum=r.Enum,Instance=r.Instance}
 for k,v in extra or {} do env[k]=v end
 return luau.load(fs.readFile(path),{environment=env,debugName=path})()
end
local passed=0
local function check(ok,name) assert(ok,name); passed+=1; print('PASS Meeseeks: '..name) end
local config=load('src/shared/Meeseeks/Config.luau')
local commands=load('src/shared/Meeseeks/Commands.luau')
for alias,canonical in commands.Aliases do check(commands.parse('/'..alias)==canonical,'parse /'..alias) end
check(commands.parse('/kill person in front of me')=='attack' and commands.parse('/attack person in front of me')=='attack','attack/kill phrase')
check(commands.parse('/follow me')=='follow' and commands.parse('/ms FOLLOW me')=='follow','namespaced and case-insensitive follow')
check(commands.parse('/meeseeks wave')=='wave','long namespace')
check(commands.parse('/kill anyone')==nil and commands.parse('/killbob')==nil and commands.parse('dance')==nil,'reject ambiguous targets and prefixes')
check(commands.parse({})==nil and commands.parse(string.rep('x',121))==nil,'reject malformed/oversized commands')
local models=load('src/server/Meeseeks/Models.luau',{game={GetService=function() return {Shared={Meeseeks={Config=config}}} end},require=function(v) return v end})
local box=models.box()
check(box:IsA('Tool') and box.Handle and box.Button.ButtonPress and box:GetAttribute('MeeseeksBox'),'usable box with pressable blue button')
local npc=models.npc(r.CFrame.new(),42)
check(npc.Humanoid and npc.HumanoidRootPart and npc:GetAttribute('MeeseeksOwner')==42,'NPC has complete character and ownership')
check(npc.Torso.Neck.Part1==npc.Head and npc.Torso['Right Shoulder'].Part1==npc['Right Arm'],'NPC humanoid joints connect')
local count=0
for _,item in npc:GetDescendants() do if item:IsA('BasePart') then count+=1 end end
check(count<=15 and npc.Head:FindFirstChildOfClass('SpecialMesh')~=nil,'recognizable rounded rig stays within 15 parts')
-- Exercise the production target selector using controlled ray/overlap responses.
local folder=r.Instance.new('Folder')
local owner=models.npc(r.CFrame.new(),1); owner.Parent=folder
local other=models.npc(r.CFrame.new(0,0,-12),2); other:SetAttribute('MeeseeksOwner',nil); other.Parent=folder
local behind=models.npc(r.CFrame.new(0,0,8),3); behind:SetAttribute('MeeseeksOwner',nil); behind.Parent=folder
local helper=models.npc(r.CFrame.new(3,0,0),1); helper.Parent=folder
for _,m in {owner,other,behind,helper} do m.HumanoidRootPart.Position=m.HumanoidRootPart.CFrame.Position end
local blocked=false
local world=r.Instance.new('Workspace'); folder.Parent=world
r.implementMethod('Workspace','GetPartBoundsInRadius',function() return {other.HumanoidRootPart,behind.HumanoidRootPart} end)
r.implementMethod('Workspace','Raycast',function() if blocked then return {Instance=r.Instance.new('Part')} end return nil end)
local player={Character=owner}
local players={GetPlayers=function() return {player} end,GetPlayerFromCharacter=function(_,char) return char==owner and player or nil end}
local targeting=load('src/server/Meeseeks/Targeting.luau',{game={GetService=function(_,s) return s=='Players' and players or {Shared={Meeseeks={Config=config}}} end},
 require=function(v) return v end,workspace=world,OverlapParams={new=function() return {} end},RaycastParams={new=function() return {} end}})
check(targeting.front(player,helper)==other,'select target ahead, never owner or behind')
blocked=true; check(targeting.front(player,helper)==nil,'wall blocks target selection'); blocked=false
other:SetAttribute('PhoenixBusy',true); check(targeting.front(player,helper)==nil,'Phoenix-protected characters excluded'); other:SetAttribute('PhoenixBusy',nil)
local ff=r.Instance.new('ForceField'); ff.Parent=other
check(targeting.front(player,helper)==nil,'ForceField-protected targets excluded'); ff:Destroy()
check(not targeting.inCone(r.Vector3.zero,r.Vector3.new(0,0,-1),r.Vector3.new(20,0,-2)) and not targeting.inCone(r.Vector3.zero,r.Vector3.new(0,0,-1),r.Vector3.new(0,0,-100)),'reject side and excessive-distance targets')
local dealt=0
r.implementMethod('Humanoid','TakeDamage',function(_,amount) dealt+=amount end)
local actor={target=other,owner=player,root=helper.HumanoidRootPart,model=helper}
check(not targeting.strike(actor) and dealt==0,'out-of-melee-range command cannot remotely damage target')
helper.HumanoidRootPart.CFrame=r.CFrame.new(0,0,-10)
helper.HumanoidRootPart.Position=r.Vector3.new(0,0,-10)
check(targeting.strike(actor) and dealt==config.Damage,'in-range visible hit deals configured damage')
blocked=true; check(not targeting.strike(actor) and dealt==config.Damage,'wall rechecked for each hit')
-- Delayed path results must never resurrect a cancelled task; concurrency is bounded.
local jobs={}
local paths={CreatePath=function() return {Status=r.Enum.PathStatus.Success,ComputeAsync=function() end,GetWaypoints=function() return {{Position=r.Vector3.zero},{Position=r.Vector3.new(0,0,-10)}} end} end}
local nav=load('src/server/Meeseeks/Navigation.luau',{
 game={GetService=function(_,service) return service=='PathfindingService' and paths or {Shared={Meeseeks={Config=config}}} end},
 require=function(v) return v end,task={spawn=function(fn) table.insert(jobs,fn) end},
})
local function navActor() return {generation=0,nextPath=0,root={Position=r.Vector3.zero},hum={Parent=true,Move=function() end,MoveTo=function() end}} end
local a=navActor()
nav.move(a,r.Vector3.new(0,0,-10),1); nav.cancel(a); jobs[1](); table.clear(jobs)
check(a.waypoints==nil and nav.pending==0,'cancelled task ignores late asynchronous path result')
local b,c,d=navActor(),navActor(),navActor()
nav.move(b,r.Vector3.one,2); nav.move(c,r.Vector3.one,2); nav.move(d,r.Vector3.one,2)
check(#jobs==2 and not d.pathBusy and nav.pending==2,'global concurrent path computation cap enforced')
for _,job in jobs do job() end
check(nav.pending==0 and b.waypoints and c.waypoints,'completed path jobs release global capacity')
print(string.format('%d Meeseeks checks passed. Studio chat, pathfinding and visual checks remain required.',passed))
