local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local remote = ReplicatedStorage:WaitForChild("PortalRemote")
-- Ensure shared modules have replicated before requiring the client modules.
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Portal"):WaitForChild("Config")
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "PortalClientEffects", workspace
local effects = require(script.Portal.Effects).new(folder)
local fluid = require(script.Portal.Fluid).new(effects)
local renderer = require(script.Portal.Renderer).new(effects, fluid)
local gunView = require(script.Portal.GunView).new()
local hud = require(script.Portal.Hud).new()
remote.OnClientEvent:Connect(function(action, data)
	if action == "Shot" then effects:shot(data)
	elseif action == "Impact" then
		effects:burst(data.position, data.valid, data.valid and 10 or 5)
		effects:sound(data.valid and "Impact" or "Fail", data.position)
	elseif action == "Open" then renderer:make(data, false)
	elseif action == "Close" then renderer:close(data.key, false)
	elseif action == "Status" then hud:status(data)
	elseif action == "Snapshot" then
		renderer:reset()
		for _, portal in data.portals do renderer:make(portal, true) end
		hud:status({nextSlot = data.nextSlot})
	elseif action == "Transit" then
		for _, cf in {data.source, data.destination} do
			effects:burst(cf.Position + cf.ZVector*0.5, true, 9)
			fluid:emit(cf, 4, false)
			effects:sound("Transit", cf.Position)
		end
		if data.userId == Players.LocalPlayer.UserId then
			hud:transit()
			local camera = workspace.CurrentCamera
			if camera then camera.CFrame = CFrame.new(camera.CFrame.Position) * data.rotation * camera.CFrame.Rotation end
		end
	end
end)
require(script.Portal.Input).start(remote, function(tool) gunView:shot(tool) end)
remote:FireServer("Sync")
Players.LocalPlayer.CharacterAdded:Connect(function()
	hud:status({nextSlot = "A", message = "New chamber ready"})
end)
RunService.RenderStepped:Connect(function(dt)
	effects:step()
	gunView:step(dt)
	hud:step()
end)
RunService.Heartbeat:Connect(function(dt)
	fluid:step(math.min(dt, 0.05))
	renderer:step(dt)
end)
