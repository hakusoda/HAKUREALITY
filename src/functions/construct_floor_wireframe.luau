--!strict
return function(wireframe: WireframeHandleAdornment)
	wireframe:Clear()

	local gap = 128
	local amount = 32 * gap
	local length = 16 * gap
	for i = 1, amount, gap do
		local start = -amount / 2
		local multiple = start + i
		wireframe:AddLine(-Vector3.zAxis * length + Vector3.xAxis * multiple, Vector3.zAxis * length + Vector3.xAxis * multiple)
		wireframe:AddLine(-Vector3.xAxis * length + Vector3.zAxis * multiple, Vector3.xAxis * length + Vector3.zAxis * multiple)
	end
end