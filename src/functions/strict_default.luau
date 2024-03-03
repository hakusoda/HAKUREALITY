--!strict
return function<T>(value: any, default_value: T): T
	if typeof(value) == typeof(default_value) then
		return value
	end
	return default_value
end