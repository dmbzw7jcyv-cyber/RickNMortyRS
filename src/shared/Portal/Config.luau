-- Shared tuning. Sound IDs are deliberately blank: supply assets your experience owns.
return table.freeze({
	Width = 7, Height = 10, Range = 180, ShotCooldown = 0.42,
	ProjectileSpeed = 210, OpenTime = 0.28, CloseTime = 0.55,
	ExitLock = 0.65, MaxTransitSpeed = 240, EffectDistance = 260,
	MaxVisiblePortals = 12, MaxDroplets = 90, MaxTransientParts = 130, BuildTestChamber = true,
	Green = Color3.fromRGB(80, 240, 20), Lime = Color3.fromRGB(155, 255, 70),
	Dark = Color3.fromRGB(9, 94, 15),
	Sounds = { Fire = "", Impact = "", Fail = "", Open = "", Close = "", Transit = "", Hum = "" },
})
