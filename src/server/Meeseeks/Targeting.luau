local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Targeting={}
function Targeting.valid(model,ownerCharacter)
 if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) or model==ownerCharacter
  or model:GetAttribute("MeeseeksOwner") or model:GetAttribute("PhoenixBusy") or model:FindFirstChildOfClass("ForceField") then return nil end
 local hum,root=model:FindFirstChildOfClass("Humanoid"),model:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health<=0 or not root then return nil end
 if not Config.AttackPlayers and Players:GetPlayerFromCharacter(model) then return nil end
 return hum,root
end
function Targeting.inCone(origin,look,position)
 local delta=position-origin
 local distance=delta.Magnitude
 return distance>0.1 and distance<=Config.TargetRange and look:Dot(delta.Unit)>=math.cos(math.rad(Config.TargetConeDegrees))
end
function Targeting.visible(origin,target,ignore)
 local root=target:FindFirstChild("HumanoidRootPart")
 if not root then return false end
 local params=RaycastParams.new(); params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,ignore
 local hit=workspace:Raycast(origin,root.Position-origin,params)
 return not hit or hit.Instance:IsDescendantOf(target)
end
function Targeting.front(player,helper)
 local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root then return nil end
 local candidates={}
 for _,p in Players:GetPlayers() do if p.Character then candidates[p.Character]=true end end
 local params=OverlapParams.new(); params.FilterType,params.FilterDescendantsInstances,params.MaxParts=Enum.RaycastFilterType.Exclude,{char,helper},128
 for _,part in workspace:GetPartBoundsInRadius(root.Position,Config.TargetRange,params) do
  local model=part:FindFirstAncestorOfClass("Model"); if model then candidates[model]=true end
 end
 local best,score=nil,math.huge
 for model in candidates do
  local hum,other=Targeting.valid(model,char)
  if hum and Targeting.inCone(root.Position,root.CFrame.LookVector,other.Position) and Targeting.visible(root.Position,model,{char,helper}) then
   local delta=other.Position-root.Position
   local value=(1-root.CFrame.LookVector:Dot(delta.Unit))*Config.TargetRange+delta.Magnitude*0.1
   if value<score then best,score=model,value end
  end
 end
 return best
end
function Targeting.strike(actor)
 local hum,root=Targeting.valid(actor.target,actor.owner.Character)
 local ownerRoot=actor.owner.Character and actor.owner.Character:FindFirstChild("HumanoidRootPart")
 if not hum or not ownerRoot or (root.Position-ownerRoot.Position).Magnitude>Config.TargetRange*2 then return false end
 if (root.Position-actor.root.Position).Magnitude<=Config.AttackRange and Targeting.visible(actor.root.Position,actor.target,{actor.model,actor.owner.Character}) then
  hum:TakeDamage(Config.Damage); return true
 end
 return false
end
return Targeting
