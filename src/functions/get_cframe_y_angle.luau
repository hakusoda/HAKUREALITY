--!strict
-- returns how far the cframe is rotated about the y axis
-- based on https://github.com/AxisAngles/Math-Gems/blob/main/CFrameAngleAboutCardinalAxis.lua
return function(cframe: CFrame)
	local _,_,_,xx, _,zx, _,_,_,xz, _,zz = cframe:GetComponents()
	return math.atan2(zx - xz, xx + zz)
end