--!strict
-- based on https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/104
-- not fully optimised
local I16_PRECISION = 32767
local CFRAME_BUFFER_SIZE = 19
function decompress_quaternion(index: number, v: Vector3)
	v /= I16_PRECISION
	
	local mult = v * v
	local d = math.sqrt(1 - (mult.X + mult.Y + mult.Z))
	if index == 1 then
		return d, v.X, v.Y, v.Z
	elseif index == 2 then
		return v.X, d, v.Y, v.Z
	elseif index == 3 then
		return v.X, v.Y, d, v.Z
	end

	return v.X, v.Y, v.Z, d
end

return function(target_buffer: buffer, offset: number): (CFrame, number)
	local x = buffer.readf32(target_buffer, offset)
	local y = buffer.readf32(target_buffer, offset + 4)
	local z = buffer.readf32(target_buffer, offset + 8)

	local qi = buffer.readu8(target_buffer, offset + 12)
	local q0 = buffer.readi16(target_buffer, offset + 13)
	local q1 = buffer.readi16(target_buffer, offset + 15)
	local q2 = buffer.readi16(target_buffer, offset + 17)

	local qx, qy, qz, qw = decompress_quaternion(qi, Vector3.new(q0, q1, q2))
	return CFrame.new(x, y, z, qx, qy, qz, qw), CFRAME_BUFFER_SIZE
end