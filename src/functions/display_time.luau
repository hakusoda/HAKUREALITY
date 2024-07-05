--!strict
return function(seconds: number)
	if seconds < 0.001 then
		return `{math.floor(seconds * 1e+6)} microseconds`
	elseif seconds < 1 then
		return `{math.floor(seconds * 1000)} milliseconds`
	end
	
	return `{math.floor(seconds)} seconds`
end