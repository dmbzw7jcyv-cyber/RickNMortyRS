local Players = game:GetService("Players")
Players.CharacterAutoLoads = false -- Phoenix owns initial spawn and every death thereafter.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.AvatarStyle).start()
local Config = require(ReplicatedStorage.Shared.Portal.Config)
local remote = Instance.new("RemoteEvent")
remote.Name = "PortalRemote"
remote.Parent = ReplicatedStorage
if Config.BuildTestChamber then require(script.Portal.Chamber).build() end
require(script.Portal.Service).start(remote)

local phoenixRemote = Instance.new("RemoteEvent")
phoenixRemote.Name, phoenixRemote.Parent = "PhoenixRemote", ReplicatedStorage
local phoenixOK, phoenixError = xpcall(function()
	local lab = require(script.Phoenix.Lab).build()
	require(script.Phoenix.Service).start(phoenixRemote, lab)
	require(script.Phoenix.Storage).start(lab)
end, debug.traceback)
if not phoenixOK then
	warn("Phoenix startup failed; restoring Roblox automatic respawn", phoenixError)
	Players.CharacterAutoLoads = true
	phoenixRemote:Destroy()
	for _, player in Players:GetPlayers() do
		if not player.Character then task.spawn(function() pcall(function() player:LoadCharacterAsync() end) end) end
	end
end
