local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Portal.Config)
local GunView = {}
GunView.__index = GunView
function GunView.new()
	return setmetatable({tool = nil, grip = nil, recoil = 0, hum = nil}, GunView)
end
function GunView:shot(tool)
	if self.tool ~= tool then self:bind(tool) end
	self.recoil = 1
end
function GunView:bind(tool)
	if self.tool and self.tool.Parent and self.grip then self.tool.Grip = self.grip end
	if self.hum then self.hum:Destroy(); self.hum = nil end
	self.tool, self.grip, self.recoil = tool, tool and tool.Grip, 0
	if tool and Config.Sounds.Hum ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId, sound.Volume, sound.Looped, sound.RollOffMaxDistance = Config.Sounds.Hum, 0.12, true, 18
		sound.Parent, self.hum = tool:FindFirstChild("EnergyCore"), sound
		sound:Play()
	end
end
function GunView:step(dt)
	local character = Players.LocalPlayer.Character
	local tool = character and character:FindFirstChild("Portal Gun")
	if tool ~= self.tool then self:bind(tool) end
	if not tool then return end
	self.recoil = math.max(0, self.recoil - dt*6)
	tool.Grip = self.grip * CFrame.new(0, 0, self.recoil*0.2) * CFrame.Angles(-self.recoil*0.14, 0, math.sin(os.clock()*1.8)*0.008)
	local core = tool:FindFirstChild("EnergyCore")
	if core then
		local pulse = 0.5+0.5*math.sin(os.clock()*5)
		core.Color = Config.Green:Lerp(Config.Lime, pulse*0.45)
		local light = core:FindFirstChildOfClass("PointLight")
		if light then light.Brightness = 0.6+pulse*0.4+self.recoil end
	end
	if self.hum then self.hum.PlaybackSpeed = 0.97+math.sin(os.clock()*2)*0.03+self.recoil*0.1 end
end
return GunView
