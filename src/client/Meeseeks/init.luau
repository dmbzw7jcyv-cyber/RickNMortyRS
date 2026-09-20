local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Meeseeks={}
function Meeseeks.start()
 local remote=game:GetService("ReplicatedStorage"):WaitForChild("MeeseeksRemote",15)
 if not remote then return end
 local player=Players.LocalPlayer
 local Effects,Emotes=require(script.Effects),require(script.Emotes)
 local gui=Instance.new("ScreenGui"); gui.Name,gui.ResetOnSpawn,gui.DisplayOrder,gui.Parent="MeeseeksHelp",false,45,player:WaitForChild("PlayerGui")
 local label=Instance.new("TextLabel"); label.AnchorPoint,label.Position,label.Size=Vector2.new(0.5,1),UDim2.fromScale(0.5,0.82),UDim2.new(0.88,0,0,48)
 label.BackgroundColor3,label.BackgroundTransparency,label.TextColor3=Color3.fromRGB(21,38,48),0.15,Color3.fromRGB(190,241,255)
 label.Font,label.TextSize,label.TextWrapped,label.Visible,label.Parent=Enum.Font.Gotham,15,true,false,gui
 Instance.new("UICorner",label).CornerRadius=UDim.new(0,10)
 local noticeId=0
 local function notice(text)
  noticeId+=1; local id=noticeId; label.Text,label.Visible=text,true
  task.delay(4,function() if id==noticeId then label.Visible=false end end)
 end
 local bound=setmetatable({},{__mode="k"})
 local lastUse=0
 local function bind(tool)
  if not tool:IsA("Tool") or not tool:GetAttribute("MeeseeksBox") or bound[tool] then return end
  bound[tool]=true
  tool.Activated:Connect(function()
   if os.clock()-lastUse<0.5 then return end
   lastUse=os.clock(); remote:FireServer("Summon")
  end)
  tool.Equipped:Connect(function() notice("Click / tap: summon Meeseeks. Chat /ms follow, /ms dance or /ms attack.") end)
 end
 local backpackConnection, characterConnection
 local function characterAdded(character)
  if backpackConnection then backpackConnection:Disconnect(); backpackConnection=nil end
  if characterConnection then characterConnection:Disconnect(); characterConnection=nil end
  for _,item in character:GetChildren() do bind(item) end
  characterConnection=character.ChildAdded:Connect(bind)
  local backpack=player:WaitForChild("Backpack",10)
  if backpack and player.Character==character then for _,item in backpack:GetChildren() do bind(item) end; backpackConnection=backpack.ChildAdded:Connect(bind) end
 end
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then task.spawn(characterAdded,player.Character) end
 remote.OnClientEvent:Connect(function(action,data,tool)
  if action=="Notice" then notice(data)
  elseif action=="Spawn" or action=="Despawn" or action=="Hit" then
   Effects.play(action,data); if action=="Spawn" then Effects.press(tool) end
  end
 end)
 local actors={}
 local nextScan=0
 RunService.PreSimulation:Connect(function()
  local now=workspace:GetServerTimeNow()
  if os.clock()>=nextScan then
   nextScan=os.clock()+0.5
   local folder=workspace:FindFirstChild("Meeseeks Helpers")
   if folder then for _,model in folder:GetChildren() do if not actors[model] then actors[model]=Emotes.bind(model) else Emotes.refresh(actors[model]) end end end
  end
  local camera=workspace.CurrentCamera
  for model,actor in actors do
   if not model.Parent then actors[model]=nil
   elseif camera and actor.root and (actor.root.Position-camera.CFrame.Position).Magnitude<180 then
    Emotes.step(actor,now)
   end
  end
 end)
end
return Meeseeks
