local PathfindingService=game:GetService("PathfindingService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Navigation={pending=0}
function Navigation.cancel(actor)
 actor.generation+=1; actor.waypoints=nil; actor.goal=nil; actor.pathBusy=false
 if actor.hum.Parent then actor.hum:Move(Vector3.zero); actor.hum:MoveTo(actor.root.Position) end
end
function Navigation.move(actor,goal,now)
 actor.goal=goal
 if not actor.pathBusy and now>=actor.nextPath and Navigation.pending<Config.MaxConcurrentPaths then
  actor.pathBusy=true; actor.nextPath=now+Config.RepathInterval
  local generation=actor.generation
  Navigation.pending+=1
  task.spawn(function()
   local ok,path=pcall(function()
    local result=PathfindingService:CreatePath({AgentRadius=1.25,AgentHeight=6.7,AgentCanJump=true,WaypointSpacing=4})
    result:ComputeAsync(actor.root.Position,goal); return result
   end)
   Navigation.pending-=1
   if actor.removed or generation~=actor.generation then return end
   actor.pathBusy=false
   if ok and path.Status==Enum.PathStatus.Success then actor.waypoints,actor.waypoint=path:GetWaypoints(),2
   else actor.waypoints=nil end
  end)
 end
 local points=actor.waypoints
 if not points then return end
 local point=points[actor.waypoint]
 if not point then return end
 local delta=point.Position-actor.root.Position
 if Vector3.new(delta.X,0,delta.Z).Magnitude<2 then actor.waypoint+=1; point=points[actor.waypoint] end
 if point then
  if point.Action==Enum.PathWaypointAction.Jump then actor.hum.Jump=true end
  actor.hum:MoveTo(point.Position)
 end
end
function Navigation.spawnCF(character,folder)
 local root=character:FindFirstChild("HumanoidRootPart")
 if not root then return nil end
 local params=RaycastParams.new(); params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{character,folder}
 params.RespectCanCollide=true
 for _,offset in {Vector3.new(5,0,-4),Vector3.new(-5,0,-4),Vector3.new(0,0,7),Vector3.new(7,0,3)} do
  local candidate=root.CFrame:PointToWorldSpace(offset)
  local wall=workspace:Raycast(root.Position,candidate-root.Position,params)
  local hit=not wall and workspace:Raycast(candidate+Vector3.new(0,5,0),Vector3.new(0,-14,0),params)
  if hit and hit.Normal.Y>0.8 then
   local center=hit.Position+Vector3.new(0,3.2,0)
   local occupied=false
   for _,helper in folder:GetChildren() do
    local helperRoot=helper:FindFirstChild("HumanoidRootPart")
    if helperRoot and (helperRoot.Position-center).Magnitude<3 then occupied=true; break end
   end
   local overlap=OverlapParams.new(); overlap.FilterType,overlap.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{character,folder}; overlap.RespectCanCollide=true
   if not occupied and #workspace:GetPartBoundsInBox(CFrame.new(center+Vector3.new(0,0.2,0)),Vector3.new(2.5,6.2,2.5),overlap)==0 then
    return CFrame.lookAt(center,center+Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z))
   end
  end
 end
 return nil
end
return Navigation
