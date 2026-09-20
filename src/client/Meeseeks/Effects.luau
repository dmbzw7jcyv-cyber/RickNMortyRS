local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Config)
local Effects={count=0}
function Effects.play(kind,position)
 local camera=workspace.CurrentCamera
 if not camera or (camera.CFrame.Position-position).Magnitude>180 or Effects.count>=18 then return end
 Effects.count+=1
 local host=Instance.new("Part"); host.Name,host.Size,host.CFrame,host.Transparency="Meeseeks poof",Vector3.one*0.1,CFrame.new(position),1
 host.Anchored,host.CanCollide,host.CanTouch,host.CanQuery,host.Parent=true,false,false,false,workspace
 host.Destroying:Once(function() Effects.count-=1 end); Debris:AddItem(host,2)
 local emitter=Instance.new("ParticleEmitter"); emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
 emitter.Color,emitter.LightEmission,emitter.Rate=ColorSequence.new(Config.Blue,Color3.fromRGB(216,255,255)),0.7,0
 emitter.Size,emitter.Transparency=NumberSequence.new(0.9,2),NumberSequence.new(0.2,1)
 emitter.Lifetime,emitter.Speed,emitter.SpreadAngle=NumberRange.new(0.3,0.75),NumberRange.new(2,6),Vector2.new(180,180)
 emitter.Parent=host; emitter:Emit(kind=="Hit" and 5 or 22)
 local light=Instance.new("PointLight"); light.Color,light.Range,light.Brightness,light.Parent=Config.Blue,9,1.5,host
 TweenService:Create(light,TweenInfo.new(0.4),{Brightness=0}):Play()
 local id=Config.Sounds[kind]
 if id and id~="" then
  local sound=Instance.new("Sound"); sound.SoundId,sound.Volume,sound.RollOffMaxDistance,sound.Parent=id,0.45,70,host; sound:Play()
 end
end
function Effects.press(tool)
 local button=tool and tool:FindFirstChild("Button")
 local weld=button and button:FindFirstChild("ButtonPress")
 if not weld then return end
 local original=weld.C0
 TweenService:Create(weld,TweenInfo.new(0.09),{C0=CFrame.new(0,-0.1,0)*original}):Play()
 Effects.play("Activate",button.Position)
 task.delay(0.12,function() if weld.Parent then TweenService:Create(weld,TweenInfo.new(0.14),{C0=original}):Play() end end)
end
return Effects
