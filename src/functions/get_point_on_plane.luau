--!strict
function squared_dist(vector: Vector3)
	return vector.X ^ 2 + vector.Y ^ 2 + vector.Z ^ 2
end

return function(plane: CFrame, point: Vector3)
	local normal = plane.LookVector
	local lambda = (plane.Position - point):Dot(normal) / squared_dist(normal)
	return point + lambda * normal
end