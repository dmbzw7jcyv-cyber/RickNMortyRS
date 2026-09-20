local Config=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Nav,Targeting=require(script.Parent.Navigation),require(script.Parent.Targeting)
local Controller={}
local phrases={dance="Can do! Watch these moves!",follow="Lead the way!",comehere="Coming, Rick!",stop="Standing by!",jump="Up we go!",wave="Hey! Look at me!",sit="A sitting task! Easy!",point="Over there!",attack="Okay! I'll handle it!"}
function Controller.say(actor,line)
 local gui=actor.model.Head:FindFirstChild("Speech")
 if gui then gui.Line.Text=line; gui.Enabled=true; actor.speechUntil=os.clock()+3.5 end
end
function Controller.mode(actor,mode,now)
 actor.mode,actor.modeAt=mode,now
 actor.model:SetAttribute("Action",mode); actor.model:SetAttribute("ActionAt",workspace:GetServerTimeNow())
end
function Controller.command(actor,command)
 local target
 if command=="attack" then
  target=Targeting.front(actor.owner,actor.model)
  if not target then Controller.say(actor,"There's nobody there!"); return end
 end
 Nav.cancel(actor); actor.target=nil; actor.hum.Sit=false
 local now=os.clock()
 actor.started,actor.lastProgress,actor.lastPosition=now,now,actor.root.Position
 actor.comeGoal=actor.owner.Character.HumanoidRootPart.Position
 if command=="attack" then actor.target=target end
 if command=="jump" then actor.hum.Jump=true end
 Controller.mode(actor,command,now); Controller.say(actor,phrases[command] or "Okay!")
end
function Controller.step(actor,now)
 local speech=actor.model.Head:FindFirstChild("Speech")
 if speech and now>(actor.speechUntil or 0) then speech.Enabled=false end
 local char=actor.owner.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 or char:GetAttribute("PhoenixBusy") then
  if actor.mode~="idle" then Nav.cancel(actor); actor.hum.Sit=false; Controller.mode(actor,"idle",now) end
  return
 end
 local mode=actor.mode
 local goal
 if mode=="follow" then
  if (root.Position-actor.root.Position).Magnitude>Config.FollowDistance then goal=root.Position-root.CFrame.LookVector*Config.FollowDistance*0.7
  else actor.hum:MoveTo(actor.root.Position); actor.lastProgress=now end
 elseif mode=="comehere" then
  if (actor.comeGoal-actor.root.Position).Magnitude<4 then
   Nav.cancel(actor); Controller.mode(actor,"idle",now); Controller.say(actor,"Task complete!")
  else goal=actor.comeGoal end
 elseif mode=="attack" then
  local targetHum,targetRoot=Targeting.valid(actor.target,char)
  if not targetHum then Nav.cancel(actor); Controller.mode(actor,"idle",now); Controller.say(actor,"All done!"); return end
  if (targetRoot.Position-root.Position).Magnitude>Config.TargetRange*2 then Nav.cancel(actor); Controller.mode(actor,"idle",now); Controller.say(actor,"They got away!"); return end
  goal=targetRoot.Position
  if (goal-actor.root.Position).Magnitude<=Config.AttackRange then
   actor.hum:MoveTo(actor.root.Position); goal=nil
   if now-actor.lastHit>=Config.AttackCooldown then
    actor.lastHit=now
    if Targeting.strike(actor) then
     actor.model:SetAttribute("HitAt",workspace:GetServerTimeNow()); actor.remote:FireAllClients("Hit",actor.root.Position)
    end
   end
  end
 end
 if goal then Nav.move(actor,goal,now) end
 if (actor.root.Position-actor.lastPosition).Magnitude>0.5 then actor.lastProgress,actor.lastPosition=now,actor.root.Position end
 if (goal and now-actor.lastProgress>7) or (mode=="attack" or mode=="comehere") and now-actor.started>Config.TaskTimeout then
  Nav.cancel(actor); Controller.mode(actor,"idle",now); Controller.say(actor,"Existence is pain! I can't reach it!")
 elseif (mode=="wave" or mode=="jump" or mode=="point" or mode=="dance") and now-actor.modeAt> (mode=="dance" and 8 or 2.3) then
  Controller.mode(actor,"idle",now); Controller.say(actor,"Ooh, can do! What's next?")
 elseif mode=="sit" then actor.hum.Sit=true
 elseif mode=="stop" then Controller.mode(actor,"idle",now)
 elseif mode=="idle" and now>actor.nextChatter then
  actor.nextChatter=now+30; Controller.say(actor,"I'm Mr. Meeseeks! Give me a task!")
 end
end
return Controller
