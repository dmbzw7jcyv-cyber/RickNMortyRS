local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Portal.Config)
local Input = {}
function Input.start(remote, onShot)
	local player, lastShot = Players.LocalPlayer, -math.huge
	local function fire(position)
		local character = player.Character
		local tool = character and character:FindFirstChild("Portal Gun")
		local camera = workspace.CurrentCamera
		if not camera or not tool or not tool:IsA("Tool") or not tool:GetAttribute("PortalGun") then return end
		if UserInputService:GetFocusedTextBox() or os.clock()-lastShot < Config.ShotCooldown then return end
		lastShot = os.clock()
		local inset = GuiService:GetGuiInset()
		local point = position - inset
		local ray = camera:ScreenPointToRay(point.X, point.Y)
		remote:FireServer("Fire", ray.Origin, ray.Direction.Unit)
		onShot(tool)
	end
	-- Do not also use Tool.Activated: mobile taps would otherwise submit twice.
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then fire(UserInputService:GetMouseLocation()) end
	end)
	UserInputService.TouchTapInWorld:Connect(function(position, processed)
		if not processed then fire(position) end
	end)
end
return Input
