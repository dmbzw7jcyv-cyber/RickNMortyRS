-- Pure decisions shared with offline regression tests; no client authority.
local Policy = {}
function Policy.choose(config, randomValue)
	local forced = config.Debug.ForceExitVariation
	if forced == "Normal" or forced == "Breakout" then return forced end
	local normal = math.max(0, tonumber(config.ExitWeights.Normal) or 0)
	local breakout = math.max(0, tonumber(config.ExitWeights.Breakout) or 0)
	if normal+breakout <= 0 then return "Normal" end
	return randomValue < normal/(normal+breakout) and "Normal" or "Breakout"
end
function Policy.current(states, player, state, token)
	return states[player] == state and state.token == token and not state.left
end
function Policy.reserve(slots, owner, create)
	for _, slot in slots do if slot.owner == owner then return slot end end
	for _, slot in slots do
		if not slot.owner then slot.owner = owner; return slot end
	end
	local slot = create(#slots+1)
	slot.owner = owner
	table.insert(slots, slot)
	return slot
end
return Policy
