local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Phoenix = {}
function Phoenix.start()
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("PhoenixRemote", 15)
	if not remote then warn("Phoenix server unavailable; leaving normal camera controls enabled"); return end
	local camera = require(script.Camera).new()
	local effects = require(script.Effects).new()
	local pose = require(script.Pose).new()
	local reported = false
	local function protect(callback)
		local ok, failure = xpcall(callback, debug.traceback)
		if not ok then
			camera:restore()
			for userId in pose.actors do pose:clear(userId) end
			for id in effects.records do effects:clear(id) end
			if not reported then warn("Phoenix client recovered from presentation error", failure); reported = true end
		end
	end
	remote.OnClientEvent:Connect(function(action, data)
		protect(function()
			if action == "Stage" then camera:stage(data); effects:stage(data); pose:stage(data)
			elseif action == "End" then camera:finish(data.token); pose:clear(Players.LocalPlayer.UserId)
			elseif action == "Reset" then effects:clear(data.chamberId) end
		end)
	end)
	RunService.RenderStepped:Connect(function(dt) protect(function() camera:step(dt); pose:step(); effects:step() end) end)
	Players.PlayerRemoving:Connect(function(player) pose:clear(player.UserId) end)
	script.Destroying:Connect(function() camera:restore(); for userId in pose.actors do pose:clear(userId) end end)
	remote:FireServer("Sync") -- Only read-only sync exists; clients cannot finish or request resurrection.
end
return Phoenix
