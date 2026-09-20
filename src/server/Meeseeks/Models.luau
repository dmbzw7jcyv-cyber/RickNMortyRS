local Config = require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Models = {}
function Models.part(parent,name,size,cf,color,anchored)
 local p=Instance.new("Part")
 p.Name,p.Size,p.CFrame,p.Color=name,size,cf,color
 p.Material,p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=Enum.Material.SmoothPlastic,anchored==true,false,false,false
 p.TopSurface,p.BottomSurface,p.Parent=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth,parent
 p:SetAttribute("PortalSurface",false)
 return p
end
local function round(p)
 local m=Instance.new("SpecialMesh"); m.MeshType,m.Parent=Enum.MeshType.Sphere,p
end
local function weld(a,b)
 local w=Instance.new("WeldConstraint"); w.Part0,w.Part1,w.Parent=a,b,b; b.Massless=true
end
function Models.label(part,text,face)
 local gui=Instance.new("SurfaceGui"); gui.Face,gui.CanvasSize,gui.Parent=face or Enum.NormalId.Front,Vector2.new(400,240),part
 local t=Instance.new("TextLabel"); t.Size,t.BackgroundTransparency,t.Text,t.TextColor3=UDim2.fromScale(1,1),1,text,Color3.fromRGB(187,237,242)
 t.Font,t.TextScaled,t.TextWrapped,t.Parent=Enum.Font.Code,true,true,gui
 return t
end
function Models.box()
 local tool=Instance.new("Tool"); tool.Name,tool.ToolTip,tool.CanBeDropped="Meeseeks Box","Click / tap to summon. Chat /ms follow or /ms dance",false
 tool:SetAttribute("MeeseeksBox",true)
 local cf=CFrame.new()
 local handle=Models.part(tool,"Handle",Vector3.new(1.25,1.25,1.25),cf,Color3.fromRGB(31,70,73)); handle.Massless=true
 for _, face in {Enum.NormalId.Front,Enum.NormalId.Back,Enum.NormalId.Left,Enum.NormalId.Right} do
  local gui=Instance.new("SurfaceGui"); gui.Face,gui.CanvasSize,gui.Parent=face,Vector2.new(128,128),handle
  local border=Instance.new("Frame"); border.Position,border.Size,border.BackgroundTransparency=UDim2.fromScale(0.07,0.07),UDim2.fromScale(0.86,0.86),1
  local stroke=Instance.new("UIStroke"); stroke.Color,stroke.Thickness,stroke.Parent=Color3.fromRGB(119,188,186),3,border; border.Parent=gui
  for _, side in {-1,1} do
   local gem=Instance.new("Frame"); gem.AnchorPoint,gem.Position,gem.Size=Vector2.new(0.5,0.5),UDim2.fromScale(0.5+side*0.12,0.5),UDim2.fromScale(0.28,0.44)
   gem.Rotation,gem.BorderSizePixel,gem.BackgroundColor3,gem.Parent=side*20,0,Color3.fromRGB(92,242,186),gui
  end
 end
 local socket=Models.part(tool,"Button socket",Vector3.new(0.14,0.65,0.65),cf*CFrame.new(0,0.66,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(14,35,41)); socket.Shape=Enum.PartType.Cylinder; weld(handle,socket)
 local button=Models.part(tool,"Button",Vector3.new(0.16,0.49,0.49),cf*CFrame.new(0,0.77,0)*CFrame.Angles(0,0,math.pi/2),Config.Blue); button.Shape,button.Material=Enum.PartType.Cylinder,Enum.Material.Neon
 local joint=Instance.new("Weld"); joint.Name,joint.Part0,joint.Part1,joint.C0,joint.Parent="ButtonPress",handle,button,handle.CFrame:ToObjectSpace(button.CFrame),button; button.Massless=true
 local light=Instance.new("PointLight"); light.Color,light.Range,light.Brightness,light.Parent=Config.Blue,4,0.35,button
 tool.Grip=CFrame.new(0,-0.25,0)*CFrame.Angles(0,0,0)
 return tool
end
function Models.npc(cf,owner)
 local model=Instance.new("Model"); model.Name="Mr. Meeseeks"; model:SetAttribute("MeeseeksOwner",owner)
 local function p(name,size,pos) return Models.part(model,name,size,cf*CFrame.new(pos),Config.Blue) end
 local root=p("HumanoidRootPart",Vector3.new(1.4,2,1),Vector3.zero); root.Transparency=1
 local torso=p("Torso",Vector3.new(1.25,2.2,0.85),Vector3.zero); round(torso); torso.CanCollide=true
 local head=p("Head",Vector3.new(2.05,1.9,1.65),Vector3.new(0,1.95,0)); round(head)
 local joints={}
 local function motor(name,a,b,c0,c1)
  local m=Instance.new("Motor6D"); m.Name,m.Part0,m.Part1,m.C0,m.C1,m.Parent=name,a,b,c0,c1,a; joints[name]=m
 end
 motor("RootJoint",root,torso,CFrame.new(),CFrame.new())
 motor("Neck",torso,head,CFrame.new(0,1.1,0),CFrame.new(0,-0.85,0))
 for _, side in {-1,1} do
  local name=side==-1 and "Left" or "Right"
  local arm=p(name.." Arm",Vector3.new(0.38,2.1,0.4),Vector3.new(side*0.85,0,0)); round(arm)
  motor(name.." Shoulder",torso,arm,CFrame.new(side*0.65,0.8,0),CFrame.new(-side*0.2,0.8,0))
  local leg=p(name.." Leg",Vector3.new(0.42,2,0.45),Vector3.new(side*0.35,-2.1,0)); round(leg)
  motor(name.." Hip",torso,leg,CFrame.new(side*0.35,-1.1,0),CFrame.new(0,1,0))
  local foot=p(name.." foot",Vector3.new(0.6,0.3,0.9),Vector3.new(side*0.35,-2.98,-0.2)); round(foot); weld(leg,foot)
 end
 for i=1,3 do
  local tuft=p("Orange tuft",Vector3.new(0.16,0.45,0.16),Vector3.new((i-2)*0.12,2.95,0)); tuft.Color=Config.Orange
  tuft.CFrame*=CFrame.Angles(0,0,(i-2)*0.55); round(tuft); weld(head,tuft)
 end
 -- A flat face carrier sits just forward of the spherical head, avoiding buried SurfaceGui details.
 local face=p("Face",Vector3.new(1.4,0.85,0.04),Vector3.new(0,1.95,-0.80)); face.Transparency=1; weld(head,face)
 local gui=Instance.new("SurfaceGui"); gui.Face,gui.CanvasSize,gui.Parent=Enum.NormalId.Front,Vector2.new(280,170),face
 local function disk(name,x,y,w,h,color)
  local f=Instance.new("Frame"); f.Name,f.Position,f.Size=name,UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
  f.BackgroundColor3,f.BorderSizePixel,f.Parent=color,0,gui; Instance.new("UICorner",f).CornerRadius=UDim.new(1,0); return f
 end
 for _,x in {98,161} do disk("Eye",x,20,19,24,Color3.fromRGB(16,22,25)); disk("Eye shine",x+4,24,5,5,Color3.new(1,1,1)) end
 disk("Smile",44,78,192,70,Color3.fromRGB(57,28,48)); disk("Tongue",109,126,70,17,Color3.fromRGB(223,102,159))
 for i=1,6 do disk("Tooth",51+i*23,80,19,13,Color3.fromRGB(249,249,235)) end
 local hum=Instance.new("Humanoid"); hum.RigType,hum.HipHeight,hum.WalkSpeed,hum.MaxHealth,hum.Health=Enum.HumanoidRigType.R6,0.1,17,100,100
 hum.DisplayDistanceType,hum.Parent=Enum.HumanoidDisplayDistanceType.None,model
 model.PrimaryPart=root
 local bubble=Instance.new("BillboardGui"); bubble.Name,bubble.Size,bubble.StudsOffset,bubble.MaxDistance= "Speech",UDim2.fromOffset(230,60),Vector3.new(0,2,0),70
 bubble.Adornee,bubble.Parent=head,head
 local text=Instance.new("TextLabel"); text.Name,text.Size,text.BackgroundColor3,text.BackgroundTransparency="Line",UDim2.fromScale(1,1),Color3.fromRGB(21,37,42),0.15
 text.TextColor3,text.Font,text.TextSize,text.TextWrapped,text.Text,text.Parent=Color3.fromRGB(218,250,255),Enum.Font.Gotham,14,true,"",bubble
 Instance.new("UICorner",text).CornerRadius=UDim.new(0,10); bubble.Enabled=false
 return model
end
return Models
