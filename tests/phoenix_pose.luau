-- Production Pose driver with reflection-backed joints and simulated replication order.
local fs, luau, r = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox')
local function load(path, extra)
 local env={CFrame=r.CFrame,Vector3=r.Vector3,Color3=r.Color3,Enum=r.Enum}
 for k,v in extra or {} do env[k]=v end
 return luau.load(fs.readFile(path),{environment=env,debugName=path})()
end
local signals={}
local function signal(instance)
 if signals[instance] then return signals[instance] end
 local s={callbacks={}}
 function s:Connect(fn)
  local c={fn=fn,live=true}; function c:Disconnect() self.live=false end
  table.insert(self.callbacks,c); return c
 end
 function s:fire(item) for _,c in self.callbacks do if c.live then c.fn(item) end end end
 signals[instance]=s; return s
end
r.implementProperty('Instance','DescendantAdded',signal)
local clock=0
local world=r.Instance.new('Folder')
local player={UserId=1}
local players={GetPlayerByUserId=function() return player end}
local shared={Motion=load('src/shared/Phoenix/Motion.luau'),Punch=load('src/shared/Phoenix/Punch.luau'),Config=load('src/shared/Phoenix/Config.luau')}
local Pose=load('src/client/Phoenix/Pose.luau',{
 game={GetService=function(_,name) return name=='Players' and players or {Shared={Phoenix=shared}} end},
 require=function(module) return module end,
 workspace={GetServerTimeNow=function() return clock end,FindFirstChild=function() return nil end},
 os={clock=function() return clock end},
})
local passed=0
local function check(ok,name) assert(ok,name); passed+=1; print('PASS pose: '..name) end
local function part(model,name,position,size)
 local p=r.Instance.new('Part'); p.Name,p.CFrame,p.Size,p.Parent=name,r.CFrame.new(position),size or r.Vector3.new(1,2,1),model; return p
end
local function joint(model,name,a,b,c0,c1,announce)
 local m=r.Instance.new('Motor6D'); m.Transform=r.CFrame.new(); m.Name,m.Part0,m.C0,m.C1,m.Parent=name,a,c0,c1,a; if b then m.Part1=b end
 if announce then signal(model):fire(m) end
 return m
end
for _,r15 in {false,true} do
 local model=r.Instance.new('Model'); model.Parent=world; player.Character=model
 local torso=part(model,'Torso',r.Vector3.new(0,6.2,-0.8),r.Vector3.new(2,2,1))
 local arm=part(model,'RightUpperArm',r.Vector3.zero)
 local controller=Pose.new()
 local function stage(phase,hit) controller:stage({userId=1,token=1,phase=phase,hit=hit,variation='Breakout',startedAt=clock,duration=1,cf=r.CFrame.new()}) end
 stage('Wake'); controller:step(1/60) -- Character is replicated, but joints are NOT yet present.
 local shoulder=joint(model,r15 and 'RightShoulder' or 'Right Shoulder',torso,arm,r.CFrame.new(1.15,0.5,0),r.CFrame.new(0,0.5,0),true)
 local elbow,wrist
 if r15 then
  local lower=part(model,'RightLowerArm',r.Vector3.zero,r.Vector3.new(0.8,1,0.8))
  local hand=part(model,'RightHand',r.Vector3.zero,r.Vector3.new(0.8,0.6,0.8))
  elbow=joint(model,'RightElbow',arm,lower,r.CFrame.new(0,-0.6,0),r.CFrame.new(0,0.5,0),true)
  wrist=joint(model,'RightWrist',lower,hand,r.CFrame.new(0,-0.5,0),r.CFrame.new(0,0.3,0),true)
 end
 local original=shoulder.C0
 stage('Pound',1)
 for _=1,35 do clock+=1/60; controller:step(1/60) end
 check(shoulder.C0~=original,(r15 and 'R15' or 'R6')..' late-replicated shoulder actually receives punch pose')
 if r15 then check(elbow.C0~=r.CFrame.new(0,-0.6,0) and controller.actors[1].punchC0[wrist] ~= nil,'R15 elbow and wrist participate') end
 local atContact=shoulder.C0
 for _=1,25 do clock+=1/60; controller:step(1/60) end
 check(shoulder.C0~=atContact,(r15 and 'R15' or 'R6')..' punch moves through contact and recoil')
 controller:clear(1)
 check(shoulder.C0==original,(r15 and 'R15' or 'R6')..' original shoulder restored')
 local extra=joint(model,'Left Shoulder',torso,arm,r.CFrame.new(),r.CFrame.new(),true)
 check(controller.actors[1]==nil and extra.C0==r.CFrame.new(),'cleared actor does not recapture joints')
 model:Destroy()
end
local controller=Pose.new()
player.Character=nil
controller:stage({userId=1,token=2,phase='Pound',hit=1,variation='Breakout',startedAt=clock,duration=1,cf=r.CFrame.new()})
controller:step(1/60)
check(controller.actors[1]~=nil,'phase received before character is retained for late replication')
local model=r.Instance.new('Model'); model.Parent=world; player.Character=model
local torso=part(model,'Torso',r.Vector3.new(0,6,-1))
local arm=part(model,'Right Arm',r.Vector3.zero)
controller:step(1/60)
local motor=joint(model,'Right Shoulder',torso,nil,r.CFrame.new(1,0.5,0),r.CFrame.new(0,0.5,0),true)
check(controller.actors[1].motors[motor]==nil,'unlinked Motor6D waits for Part1')
motor.Part1=arm
clock+=0.25; controller:step(1/60)
check(controller.actors[1].motors[motor]~=nil and motor.C0~=r.CFrame.new(1,0.5,0),'late Part1 link is picked up and animated without another stage')
controller:destroy()
local connected=false
for _,c in signal(model).callbacks do if c.live then connected=true end end
check(not connected,'pose cleanup disconnects late-joint discovery listener')
print(string.format('%d pose integration checks passed; Studio visual verification still required.',passed))
