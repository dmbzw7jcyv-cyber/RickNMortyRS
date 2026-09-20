local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Portal.Config)
local remote = Instance.new("RemoteEvent")
remote.Name = "PortalRemote"
remote.Parent = ReplicatedStorage
if Config.BuildTestChamber then require(script.Portal.Chamber).build() end
require(script.Portal.Service).start(remote)
