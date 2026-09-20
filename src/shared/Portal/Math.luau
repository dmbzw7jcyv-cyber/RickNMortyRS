local Math = {}
-- Local +Z always points out of the solid surface.
function Math.surfaceFrame(position, normal)
	local up = math.abs(normal:Dot(Vector3.yAxis)) > 0.95 and Vector3.zAxis or Vector3.yAxis
	local right = up:Cross(normal).Unit
	return CFrame.fromMatrix(position, right, normal:Cross(right).Unit, normal)
end
function Math.mapping(source, destination)
	return destination * CFrame.Angles(0, math.pi, 0) * source:Inverse()
end
function Math.finiteVector(value)
	return typeof(value) == "Vector3" and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 1e7 and math.abs(value.Y) < 1e7 and math.abs(value.Z) < 1e7
end
function Math.inEllipse(x, y, rx, ry)
	return rx > 0 and ry > 0 and (x / rx)^2 + (y / ry)^2 <= 1
end
function Math.support(cf, size, axis)
	return (math.abs(cf.RightVector:Dot(axis)) * size.X + math.abs(cf.UpVector:Dot(axis)) * size.Y
		+ math.abs(cf.ZVector:Dot(axis)) * size.Z) * 0.5
end
return Math
