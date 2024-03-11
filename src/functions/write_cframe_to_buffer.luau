--!strict
-- based on https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/104
-- not fully optimised
local FP_EPSILON = 1e-6
local I16_PRECISION = 32767
local CFRAME_BUFFER_SIZE = 19
function normalise_quaternion(cframe: CFrame): (Vector3, number)
	local axis, angle = cframe:ToAxisAngle()
	axis = axis.Magnitude > FP_EPSILON and axis.Unit or Vector3.xAxis

	local ha = angle / 2
	local w = math.cos(ha)
	local sha = math.sin(ha)
	local mult = axis * sha
	local mult2 = mult * mult

	local length = math.sqrt(mult2.X + mult2.Y + mult2.Z + w * w)
	if length < FP_EPSILON then
		return Vector3.zero, 1
	end

	local mult3 = mult / length
	return mult3, w / length
end

function compress_quaternion(cframe: CFrame): (number, Vector3)
	local q, qw = normalise_quaternion(cframe)

	local index = -1
	local value = -math.huge

	local sign = 0
	local qx, qy, qz = q.X, q.Y, q.Z
	for i = 1, 4 do
		local val = select(i, qx, qy, qz, qw)
		local abs = math.abs(val)
		if abs > value then
			index = i
			value = abs
			sign = val
		end
	end
	sign = sign >= 0 and 1 or -1

	local v: Vector3
	if index == 1 then
		v = (Vector3.new(qy, qz, qw) * sign * I16_PRECISION + Vector3.one / 2):Floor()
	elseif index == 2 then
		v = (Vector3.new(qx, qz, qw) * sign * I16_PRECISION + Vector3.one / 2):Floor()
	elseif index == 3 then
		v = (Vector3.new(qx, qy, qw) * sign * I16_PRECISION + Vector3.one / 2):Floor()
	else
		v = (q * sign * I16_PRECISION + Vector3.one / 2):Floor()
	end

	return index, v
end

return function(target_buffer: buffer, offset: number, cframe: CFrame): number
	buffer.writef32(target_buffer, offset, cframe.X)
	buffer.writef32(target_buffer, offset + 4, cframe.Y)
	buffer.writef32(target_buffer, offset + 8, cframe.Z)
	
	local qi, q = compress_quaternion(cframe)
	buffer.writeu8(target_buffer, offset + 12, qi)
	buffer.writei16(target_buffer, offset + 13, q.X)
	buffer.writei16(target_buffer, offset + 15, q.Y)
	buffer.writei16(target_buffer, offset + 17, q.Z)
	
	return CFRAME_BUFFER_SIZE
end