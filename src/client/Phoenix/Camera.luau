local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Camera = {}
Camera.__index = Camera
function Camera.new()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "PhoenixTransfer", false, true, 70
	gui.Parent = player:WaitForChild("PlayerGui")
	local fade = Instance.new("Frame")
	fade.Size, fade.BackgroundColor3, fade.BackgroundTransparency, fade.BorderSizePixel, fade.Parent = UDim2.fromScale(1, 1), Color3.new(), 1, 0, gui
	local text = Instance.new("TextLabel")
	text.Size, text.Position, text.BackgroundTransparency = UDim2.new(1, 0, 0, 50), UDim2.fromScale(0, 0.82), 1
	text.TextColor3, text.Font, text.TextSize, text.Text, text.Parent = Config.Green, Enum.Font.Code, 19, "", gui
	local lines = {}
	for i = 1, 5 do
		local line = Instance.new("Frame")
		line.Size, line.Position, line.BackgroundColor3 = UDim2.new(1, 0, 0, i%2+1), UDim2.fromScale(0, i/6), Config.Green
		line.BackgroundTransparency, line.BorderSizePixel, line.Parent = 1, 0, gui
		table.insert(lines, line)
	end
	local self = setmetatable({player = player, gui = gui, fade = fade, text = text, lines = lines, active = false}, Camera)
	task.spawn(function()
		local scripts = player:WaitForChild("PlayerScripts")
		local module = scripts:WaitForChild("PlayerModule", 10)
		if module then
			local ok, controls = pcall(function() return require(module):GetControls() end)
			if ok then self.controls = controls; if self.active then controls:Disable() end end
		end
	end)
	return self
end
function Camera:stage(data)
	if data.userId ~= self.player.UserId or data.phase == "Cooldown" or data.phase == "Damaged" then return end
	if self.token and data.token < self.token then return end
	local camera = workspace.CurrentCamera
	if not self.active then
		self.fov = camera and camera.FieldOfView or 70
		self.active, self.began = true, os.clock()
	end
	self.token, self.data, self.ending = data.token, data, nil
	if self.controls then self.controls:Disable() end
end
function Camera:restore()
	self.active, self.ending, self.data = false, nil, nil
	if self.controls then self.controls:Enable() end
	local camera = workspace.CurrentCamera
	local character = self.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then camera.CameraSubject = humanoid end
		camera.FieldOfView = self.fov or 70
	end
	self.fade.BackgroundTransparency, self.text.Text = 1, ""
	for _, line in self.lines do line.BackgroundTransparency = 1 end
end
function Camera:finish(token)
	if self.token and token and token < self.token then return end
	if self.active then self.ending = os.clock() else self:restore() end
end
function Camera:step(dt)
	if not self.active then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local character = self.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if os.clock()-self.began > Config.ClientTimeout then self:restore(); return end
	-- The replicated server attribute independently recovers a lost End event.
	if not self.ending and self.player:GetAttribute("PhoenixActive") == false and os.clock()-self.began > 0.5 then self.ending = os.clock() end
	if self.ending then
		if root then
			local target = CFrame.lookAt(root.Position+Vector3.new(0, 4, 9), root.Position+Vector3.new(0, 1, 0))
			camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt*12))
		end
		self.fade.BackgroundTransparency = 1
		self.text.Text = ""
		if os.clock()-self.ending > 0.3 then self:restore() end
		return
	end
	local data = self.data
	local elapsed = math.max(0, workspace:GetServerTimeNow()-data.startedAt)
	local t = math.clamp(elapsed/data.duration, 0, 1)
	camera.CameraType = Enum.CameraType.Scriptable
	local center = data.cf:PointToWorldSpace(Vector3.new(0, 6, 0))
	local offset = data.phase == "Pound" and Vector3.new(6, 7, -10) or Vector3.new(9, 8, -15)
	if data.phase == "Exit" or data.phase == "Burst" then offset = Vector3.new(8, 6, -16) end
	local target = CFrame.lookAt(data.cf:PointToWorldSpace(offset), center)
	camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt*7))
	camera.FieldOfView = self.fov + (data.phase == "Transfer" and math.sin(t*math.pi)*3 or 0)
	self.text.Text = "PHOENIX // " .. string.upper(data.phase == "Transfer" and "CONSCIOUSNESS TRANSFER" or data.phase)
	self.fade.BackgroundTransparency = data.phase == "Transfer" and (1-math.sin(t*math.pi)) or 1
	for i, line in self.lines do
		local glitch = data.phase == "Transfer" and elapsed < 0.45
		line.BackgroundTransparency = glitch and 0.72 or 1
		if glitch then line.Position = UDim2.fromScale(0, (i/6+math.sin(elapsed*40+i)*0.02)%1) end
	end
end
return Camera
