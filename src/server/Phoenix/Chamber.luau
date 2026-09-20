local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Phoenix.Config)
local Chamber = {}
function Chamber.tween(slot, object, duration, properties)
	local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), properties)
	table.insert(slot.tweens, tween)
	tween:Play()
end
function Chamber.fluid(slot, amount, duration)
	local height = math.max(0.08, amount*7.6)
	local cf = slot.cf*CFrame.new(0, slot.floorY+height/2, 0)*CFrame.Angles(0, 0, math.pi/2)
	Chamber.tween(slot, slot.fluid, duration, {Size = Vector3.new(height, 5.45, 5.45), CFrame = cf,
		Transparency = amount > 0.01 and 0.65 or 1})
end
function Chamber.reset(slot)
	slot.revision += 1
	for _, tween in slot.tweens do tween:Cancel() end
	table.clear(slot.tweens)
	slot.glass.CFrame, slot.glass.Transparency = slot.glassCF, 0.8
	slot.dome.CFrame, slot.dome.Transparency = slot.domeCF, 0.8
	for _, lock in slot.locks do lock.part.CFrame = lock.cf end
	slot.fluid.Size = Vector3.new(0.08, 5.45, 5.45)
	slot.fluid.CFrame = slot.cf*CFrame.new(0, slot.floorY+0.04, 0)*CFrame.Angles(0, 0, math.pi/2)
	slot.fluid.Transparency, slot.light.Brightness = 1, 0.25
	slot.lamp.Color, slot.status.Text = Config.Green, "PHOENIX / " .. slot.id .. "\nSTANDBY"
	slot.model:SetAttribute("Phase", "Idle")
end
function Chamber.stage(slot, name, duration, hit)
	slot.model:SetAttribute("Phase", name)
	slot.status.Text = "PHOENIX / " .. slot.id .. "\n" .. string.upper(name)
	if name == "Activate" then
		slot.lamp.Color, slot.light.Brightness = Config.Amber, 1.2
		Chamber.fluid(slot, 1, duration)
	elseif name == "Reconstruct" then
		slot.lamp.Color = Config.Green
	elseif name == "Drain" then
		Chamber.fluid(slot, 0, duration)
	elseif name == "Unlock" then
		for _, lock in slot.locks do Chamber.tween(slot, lock.part, duration, {CFrame = lock.cf*CFrame.new(lock.side*0.7, 0, 0)}) end
	elseif name == "Open" then
		Chamber.tween(slot, slot.glass, duration, {CFrame = slot.glassCF+Vector3.new(0, 8.6, 0), Transparency = 1})
		Chamber.tween(slot, slot.dome, duration, {CFrame = slot.domeCF+Vector3.new(0, 8.6, 0), Transparency = 1})
	elseif name == "Malfunction" or name == "Pound" then
		slot.lamp.Color = Config.Red
		slot.status.Text = "E-09 / RELEASE FAILURE\nMANUAL EGRESS" .. (hit and " / " .. hit or "")
		if name == "Pound" then
			slot.glass.CFrame = slot.glassCF+Vector3.new(0, 0, -0.07)
			Chamber.tween(slot, slot.glass, duration*0.8, {CFrame = slot.glassCF})
		end
	elseif name == "Burst" then
		slot.glass.Transparency, slot.dome.Transparency = 1, 1
		for _, lock in slot.locks do lock.part.CFrame = lock.cf*CFrame.Angles(0, 0, lock.side*0.45) end
		Chamber.fluid(slot, 0, duration)
	elseif name == "Damaged" then
		slot.lamp.Color, slot.light.Brightness = Config.Red, 0.2
		slot.status.Text = "GLASS FAILURE\nAUTO-REPAIR PENDING"
	elseif name == "Cooldown" then slot.light.Brightness = 0.3 end
end
return Chamber
