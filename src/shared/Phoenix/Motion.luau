-- Continuous, time-based poses shared by stored bodies and live resurrection rigs.
local Motion = {Contact = 0.56}
local function smooth(t) t = math.clamp(t, 0, 1); return t*t*(3-2*t) end
function Motion.strike(t)
	-- Slow wind-up, quick extension, held contact, then recoil. The final strike
	-- ends at contact so shattering follows a fist on the glass, not a withdrawn arm.
	if t < 0.3 then return -0.24*smooth(t/0.3) end
	if t < Motion.Contact then return -0.24+1.24*smooth((t-0.3)/(Motion.Contact-0.3)) end
	if t < 0.67 then return 1 end
	return 1-smooth((t-0.67)/0.33)
end
function Motion.sample(phase, t, clock, hit, variation)
	local floating = phase ~= "Exit"
	local strikeT = phase == "Pound" and (hit == 3 and math.min(t*Motion.Contact, Motion.Contact) or t) or 0
	local strike = phase == "Pound" and Motion.strike(strikeT) or (phase == "Burst" and 1-t or 0)
	local ready = phase == "Malfunction" or phase == "Pound" or phase == "Burst"
	return {
		bob = floating and math.sin(clock*1.6)*0.13 or 0,
		roll = floating and math.sin(clock*0.9)*0.035 or 0,
		strike = strike, ready = ready,
		forward = ready and 0.45+math.max(0, strike)*0.7 or 0,
		shoulder = ready and 1.05+strike*0.48 or (0.12+math.sin(clock*1.4)*0.035),
		elbow = ready and -0.7+math.max(0, strike)*0.65 or -0.18,
		lean = phase == "Exit" and variation == "Breakout" and math.sin(t*math.pi)*0.24 or -strike*0.1,
		leg = floating and 0.12+math.sin(clock*1.2)*0.045 or 0,
	}
end
return Motion
