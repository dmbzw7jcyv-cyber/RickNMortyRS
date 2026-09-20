return {
 MaxActivePerPlayer = 1, -- supported 1–3; commands address the newest helper
 SummonCooldown = 2, CommandCooldown = 0.3, Lifetime = 300,
 FollowDistance = 6, TargetRange = 45, TargetConeDegrees = 25,
 AttackRange = 4.5, Damage = 25, AttackCooldown = 0.65, AttackPlayers = true,
 TaskTimeout = 22, ThinkInterval = 0.15, RepathInterval = 1.25, MaxConcurrentPaths = 2,
 Blue = Color3.fromRGB(91, 199, 230), Orange = Color3.fromRGB(226, 124, 57),
 TestArea = Vector3.new(-91, 0, 22),
 Sounds = {Activate = "", Spawn = "", Despawn = "", Hit = ""}, -- permitted rbxassetid:// audio only
}
