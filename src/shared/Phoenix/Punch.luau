-- Analytic limb targeting: solve a fist position on the curved tank, not a generic arm swing.
local Punch = {}
function Punch.bend(shoulder, target, a, b, outward)
	local delta = target-shoulder
	local distance = math.clamp(delta.Magnitude, math.abs(a-b)+0.001, a+b-0.001)
	local direction = delta.Magnitude > 0.001 and delta.Unit or Vector3.new(0, 0, -1)
	local along = (a*a-b*b+distance*distance)/(2*distance)
	local down = outward-direction*outward:Dot(direction)
	if down.Magnitude < 0.001 then down = Vector3.xAxis-direction*direction.X end
	local elbow = shoulder+direction*along+down.Unit*math.sqrt(math.max(0, a*a-along*along))
	return elbow, shoulder+direction*distance
end
function Punch.aim(joint, localJoint, localTip, target)
	local from, toward = (localTip-localJoint).Unit, (target-joint).Unit
	local axis = from:Cross(toward)
	local dot = math.clamp(from:Dot(toward), -1, 1)
	local rotation = CFrame.new()
	if axis.Magnitude > 0.00001 then rotation = CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
	elseif dot < 0 then
		local perpendicular = math.abs(from.X) < 0.9 and from:Cross(Vector3.xAxis) or from:Cross(Vector3.yAxis)
		rotation = CFrame.fromAxisAngle(perpendicular.Unit, math.pi)
	end
	return CFrame.new(joint-rotation:VectorToWorldSpace(localJoint))*rotation
end
function Punch.contact(cf, side, height)
	local x = side*1.15
	return cf:PointToWorldSpace(Vector3.new(x, height, -math.sqrt(2.78^2-x*x)))
end
return Punch
