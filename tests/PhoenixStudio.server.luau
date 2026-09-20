-- MANUAL Studio-only integration runner. NOT mapped into Rojo / not run by offline tests.
-- In a Play session, create a temporary Script in ServerScriptService and paste this file.
-- It intentionally kills the first test player three times. Delete the Script when finished.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This test may only run in Studio")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local player = Players:GetPlayers()[1]
assert(player, "Start a Play session with a player first")
local original = Config.Debug.ForceExitVariation
local function waitUntil(predicate, limit, message)
	local finish = os.clock()+limit
	repeat if predicate() then return end; task.wait(0.05) until os.clock() > finish
	error(message)
end
local ok, failure = xpcall(function()
	for _, variation in {"Normal", "Breakout", "Random"} do
		Config.Debug.ForceExitVariation = variation
		waitUntil(function() return player.Character and player.Character:FindFirstChildOfClass("Humanoid") and not player:GetAttribute("PhoenixActive") end, 35, "Player not ready")
		local old = player.Character
		local phases = {}
		local connection = player:GetAttributeChangedSignal("PhoenixPhase"):Connect(function()
			phases[player:GetAttribute("PhoenixPhase")] = true
		end)
		old:FindFirstChildOfClass("Humanoid").Health = 0
		waitUntil(function() return player:GetAttribute("PhoenixActive") end, 2, "Actual death did not trigger Phoenix")
		waitUntil(function() return not player:GetAttribute("PhoenixActive") end, 35, "Phoenix did not release player")
		connection:Disconnect()
		local char = player.Character
		assert(char ~= old and char.Humanoid.Health > 0, "Replacement avatar missing/dead")
		assert(not char.HumanoidRootPart.Anchored and char.Humanoid.WalkSpeed > 0, "Movement was not restored")
		assert(not char:GetAttribute("PhoenixBusy"), "Busy flag leaked")
		assert(phases.Transfer and phases.Wake and phases.Exit, "Incomplete resurrection lifecycle")
		if variation == "Normal" then assert(phases.Drain and phases.Open and not phases.Burst, "Wrong normal sequence") end
		if variation == "Breakout" then assert(phases.Malfunction and phases.Pound and phases.Burst, "Wrong breakout sequence") end
		assert(player.Backpack:FindFirstChild("Portal Gun") or char:FindFirstChild("Portal Gun"), "Portal Gun not restored")
		print("PHOENIX STUDIO PASS: " .. variation)
		task.wait(Config.DamagedCooldown+0.5)
	end
end, debug.traceback)
Config.Debug.ForceExitVariation = original
assert(ok, failure)
print("Server lifecycle checks passed. Still inspect camera, glass/fluids, touch block, avatar appearance, and two-client behavior manually.")
