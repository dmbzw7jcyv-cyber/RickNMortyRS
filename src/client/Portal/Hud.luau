local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Portal.Config)
local Hud = {}
Hud.__index = Hud
function Hud.new()
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "PortalHud", false, false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local text = Instance.new("TextLabel")
	text.AnchorPoint, text.Position, text.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 12), UDim2.new(0.88, 0, 0, 60)
	text.BackgroundColor3, text.BackgroundTransparency = Color3.fromRGB(12, 24, 17), 0.18
	text.TextColor3, text.TextSize, text.TextWrapped, text.Font = Config.Lime, 15, true, Enum.Font.Code
	text.Parent = gui
	Instance.new("UICorner", text).CornerRadius = UDim.new(0, 9)
	local limit = Instance.new("UISizeConstraint", text)
	limit.MaxSize = Vector2.new(620, 60)
	local flash = Instance.new("Frame")
	flash.Size, flash.BackgroundColor3, flash.BackgroundTransparency, flash.BorderSizePixel = UDim2.fromScale(1, 1), Config.Green, 1, 0
	flash.ZIndex, flash.Parent = 0, gui
	local self = setmetatable({gui = gui, text = text, flash = flash, nextSlot = "A", message = "Click / tap a flat surface", untilTime = 0}, Hud)
	self:step()
	return self
end
function Hud:status(data)
	if data.nextSlot then self.nextSlot = data.nextSlot end
	if data.message then self.message, self.untilTime = data.message, os.clock()+2.5 end
end
function Hud:transit()
	if self.tween then self.tween:Cancel() end
	self.flash.BackgroundTransparency = 0.88
	self.tween = TweenService:Create(self.flash, TweenInfo.new(0.18), {BackgroundTransparency = 1})
	self.tween:Play()
end
function Hud:step()
	local character = Players.LocalPlayer.Character
	self.text.Visible = character ~= nil and character:FindFirstChild("Portal Gun") ~= nil
	local message = os.clock() < self.untilTime and self.message or "Click / tap a flat surface • portals link when both exist"
	self.text.Text = "DIMENSIONAL FLUID DEVICE  /  NEXT: " .. self.nextSlot .. "\n" .. message
end
return Hud
