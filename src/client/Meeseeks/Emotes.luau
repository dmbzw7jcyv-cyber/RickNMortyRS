local Emotes={}
function Emotes.bind(model)
 local actor={model=model,root=model:FindFirstChild("HumanoidRootPart"),motors={}}
 Emotes.refresh(actor)
 return actor
end
function Emotes.refresh(actor)
 actor.root=actor.model:FindFirstChild("HumanoidRootPart")
 for _,item in actor.model:GetDescendants() do if item:IsA("Motor6D") and item.Part0 and item.Part1 and not actor.motors[item] then actor.motors[item]=item.C0 end end
end
function Emotes.step(actor,now)
 local model,root=actor.model,actor.root
 if not root then return end
 local mode=model:GetAttribute("Action") or "idle"
 local t=now-(model:GetAttribute("ActionAt") or now)
 local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
 local swing=math.sin(now*9)*math.min(speed/16,1)*0.55
 local hit=math.max(0,1-(now-(model:GetAttribute("HitAt") or 0))/0.3)
 for motor,cf in actor.motors do
  if not motor.Parent then continue end
  local n=motor.Name
  local left=n:find("Left")~=nil; local side=left and -1 or 1
  local offset=CFrame.new()
  if n:find("Shoulder") then
   local x,z=-swing*side,side*0.07
   if mode=="dance" then x,z=math.sin(t*7+side)*0.7,side*(1.15+math.sin(t*5)*0.4)
   elseif mode=="wave" and not left then x,z=0.15,2.3+math.sin(t*14)*0.35
   elseif mode=="point" and not left then x,z=math.pi/2,0
   elseif mode=="sit" then x,z=0.4,side*0.2
   elseif mode=="attack" and not left then x,z=0.8+hit,0 end
   offset=CFrame.Angles(x,0,z)
  elseif n:find("Hip") then offset=CFrame.Angles(mode=="sit" and math.pi/2 or swing*side,0,mode=="dance" and side*0.12 or 0)
  elseif n=="RootJoint" then offset=CFrame.new(0,mode=="dance" and math.abs(math.sin(t*7))*0.15 or math.sin(now*2)*0.025,0)*CFrame.Angles(0,0,mode=="dance" and math.sin(t*6)*0.17 or 0)
  elseif n=="Neck" then offset=CFrame.Angles(0,math.sin(now*0.8)*0.12,mode=="dance" and math.sin(t*6)*0.1 or 0) end
  motor.C0=cf*offset; motor.Transform=CFrame.new()
 end
end
return Emotes
