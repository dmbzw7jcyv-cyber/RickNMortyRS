-- Timing/probabilities are server decisions. Empty audio IDs are intentional.
return {
	InitialChambers = 5, Columns = 5, Spacing = 22,
	Origin = Vector3.new(0, 0, 136),
	TransferTime = 0.45, ReconstructionTime = 1.35,
	LoadTimeout = 18, SequenceTimeout = 30, ClientTimeout = 34, RetryDelay = 2,
	NormalCooldown = 2, DamagedCooldown = 4,
	ExitWeights = {Normal = 1, Breakout = 1},
	Debug = {ForceExitVariation = "Random"}, -- nil/Random, Normal, Breakout
	Green = Color3.fromRGB(81, 226, 105), Fluid = Color3.fromRGB(91, 191, 134),
	Amber = Color3.fromRGB(255, 161, 45), Red = Color3.fromRGB(242, 65, 42),
	EffectDistance = 230, MaxTemporaryParts = 100,
	Sounds = {
		Transfer = "", Startup = "", ElectricalActivation = "", Bubbles = "",
		Pump = "", Drain = "", Locks = "", Open = "", Steam = "",
		Malfunction = "", Alarm = "", HitGlass = "", CrackGlass = "",
		BreakGlass = "", LiquidBurst = "", Sparks = "", Cooldown = "",
	},
}
