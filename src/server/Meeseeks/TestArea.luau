local Models=require(script.Parent.Models)
local Config=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Area={}
function Area.build()
 local folder=Instance.new("Folder"); folder.Name,folder.Parent="Meeseeks Test Area",workspace
 local cf=CFrame.new(Config.TestArea)
 local floor=Models.part(folder,"Helper testing deck",Vector3.new(40,1,48),cf*CFrame.new(0,0.5,0),Color3.fromRGB(62,74,79),true)
 floor.CanCollide,floor.CanQuery=true,true; floor:SetAttribute("PortalSurface",true)
 local bridge=Models.part(folder,"Walkway",Vector3.new(15,1,10),cf*CFrame.new(26,0.5,0),floor.Color,true); bridge.CanCollide,bridge.CanQuery=true,true; bridge:SetAttribute("PortalSurface",true)
 local sign=Models.part(folder,"Commands",Vector3.new(18,7,0.4),cf*CFrame.new(0,5,22),Color3.fromRGB(22,40,48),true)
 Models.label(sign,"MEESEEKS TASK LAB\nEquip Meeseeks Box • click / tap\n/ms follow • /ms dance • /ms stop\n/ms wave • /ms sit • /ms jump\nFace dummy: /ms attack",Enum.NormalId.Front)
 Models.part(folder,"KO target pad",Vector3.new(8,0.08,8),cf*CFrame.new(0,1.04,-12),Color3.fromRGB(97,156,170),true)
 local function dummy()
  if not folder.Parent then return end
  local model=Instance.new("Model"); model.Name="Meeseeks KO Dummy"
  local root=Models.part(model,"HumanoidRootPart",Vector3.new(2,2,1),cf*CFrame.new(0,4.1,-12),Color3.fromRGB(105,108,110),true)
  root.CanQuery=true
  local torso=Models.part(model,"Torso",Vector3.new(2,2,1),root.CFrame,Color3.fromRGB(182,133,66),true); torso.CanQuery=true
  local head=Models.part(model,"Head",Vector3.new(1.5,1.2,1.2),root.CFrame*CFrame.new(0,1.6,0),Color3.fromRGB(199,182,145),true); head.CanQuery=true
  local hum=Instance.new("Humanoid"); hum.RequiresNeck,hum.BreakJointsOnDeath,hum.Parent=false,false,model
  model.PrimaryPart,model.Parent=root,folder
  hum.Died:Once(function() task.delay(2,function() model:Destroy() end); task.delay(5,dummy) end)
 end
 dummy()
 return folder
end
return Area
