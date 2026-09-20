-- Runs production ownership/lifetime service with deterministic event doubles.
local fs,luau,r=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox')
local function load(path,extra)
 local env={Vector3=r.Vector3,Vector2=r.Vector2,CFrame=r.CFrame,Color3=r.Color3,UDim2=r.UDim2,UDim=r.UDim,Enum=r.Enum,Instance=r.Instance}
 for k,v in extra or {} do env[k]=v end
 return luau.load(fs.readFile(path),{environment=env,debugName=path})()
end
local function signal()
 local s={list={}}
 function s:Connect(fn) local c={fn=fn,live=true}; function c:Disconnect() self.live=false end; table.insert(self.list,c); return c end
 function s:fire(...) for _,c in self.list do if c.live then c.fn(...) end end end
 return s
end
local config=load('src/shared/Meeseeks/Config.luau')
local commands=load('src/shared/Meeseeks/Commands.luau')
local models=load('src/server/Meeseeks/Models.luau',{game={GetService=function() return {Shared={Meeseeks={Config=config}}} end},require=function(v) return v end})
local originalNPC=models.npc
models.npc=function(...) local m=originalNPC(...); m.HumanoidRootPart.Position=m.HumanoidRootPart.CFrame.Position; return m end
r.implementMethod('BasePart','SetNetworkOwner',function() end)
local world=r.Instance.new('Workspace')
local rs=r.Instance.new('ReplicatedStorage')
local now=10
local remote={OnServerEvent=signal(),FireAllClients=function() end,FireClient=function() end}
local commandsSeen={}
local chatCallback
local deps={Models=models,Navigation={spawnCF=function() return r.CFrame.new(0,4,0) end,cancel=function(actor) actor.generation+=1 end},
 Controller={mode=function(actor,mode) actor.mode=mode end,say=function() end,command=function(actor,command) table.insert(commandsSeen,{owner=actor.owner,model=actor.model,command=command}) end},
 Chat={start=function(cb) chatCallback=cb end},TestArea={build=function() end}}
local function player(id)
 local p={UserId=id,CharacterAdded=signal(),CharacterRemoving=signal()}
 p.Character=models.npc(r.CFrame.new(),id); p.Character.Parent=world
 p.backpack=r.Instance.new('Backpack')
 function p:WaitForChild() return self.backpack end
 return p
end
local p1,p2=player(1),player(2)
local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function() return {p1,p2} end}
local tasks={wait=function() coroutine.yield() end,spawn=function(fn)
 local thread=coroutine.create(fn); local ok,e=coroutine.resume(thread); assert(ok,e); return thread
end}
local service=load('src/server/Meeseeks/Service.luau',{
 game={GetService=function(_,s) if s=='Players' then return players end; return {Shared={Meeseeks={Config=config,Commands=commands}}} end},
 script={Parent=deps},require=function(v) return v end,workspace=world,task=tasks,os={clock=function() return now end},
 Instance={new=function(class) return class=='RemoteEvent' and remote or r.Instance.new(class) end},warn=function() end,
})
-- ReplicatedStorage is represented by a real Instance for folder-parent assignments.
-- Remote is a plain double and accepts its parent without an engine reference.
service.start()
local helpers=world:FindFirstChild('Meeseeks Helpers')
local passed=0
local function check(ok,name) assert(ok,name); passed+=1; print('PASS Meeseeks service: '..name) end
local tool1=p1.backpack:FindFirstChild('Meeseeks Box'); local tool2=p2.backpack:FindFirstChild('Meeseeks Box')
check(tool1 and tool2,'each player receives a distinct box')
remote.OnServerEvent:fire(p1,'Summon'); check(#helpers:GetChildren()==0,'summon rejected unless exact issued tool is equipped')
tool1.Parent=p1.Character; now+=3; remote.OnServerEvent:fire(p1,'Summon')
check(#helpers:GetChildren()==1,'equipped box summons one helper')
remote.OnServerEvent:fire(p1,'Summon'); check(#helpers:GetChildren()==1,'summon spam rate limited')
tool2.Parent=p2.Character; remote.OnServerEvent:fire(p2,'Summon')
check(#helpers:GetChildren()==2,'second player gets independent helper')
chatCallback(p2,'/dance'); chatCallback(p1,'/follow')
check(#commandsSeen==2 and commandsSeen[1].owner==p2 and commandsSeen[1].model:GetAttribute('MeeseeksOwner')==2 and commandsSeen[2].owner==p1,'chat routes exclusively to summoner-owned helper')
remote.OnServerEvent:fire(p1,'Damage',p2.Character); check(#commandsSeen==2,'forged remote damage action ignored')
local first=commandsSeen[2].model
now+=3; remote.OnServerEvent:fire(p1,'Summon')
check(not first.Parent and #helpers:GetChildren()==2,'default cap cleanly replaces oldest helper')
config.MaxActivePerPlayer=3
for _=1,3 do now+=3; remote.OnServerEvent:fire(p1,'Summon') end
check(#helpers:GetChildren()==4,'configurable cap limited to three plus other player helper')
now+=1; chatCallback(p1,'/despawn'); check(#helpers:GetChildren()==3,'despawn removes newest helper only')
p1.CharacterRemoving:fire(p1.Character); check(#helpers:GetChildren()==1,'owner respawn cleans their helpers only')
players.PlayerRemoving:fire(p2); check(#helpers:GetChildren()==0,'disconnect cleans remaining helper and tool')
check(not tool2.Parent,'disconnect destroys issued box')
print(string.format('%d Meeseeks service checks passed.',passed))
