--!strict
return function(input: { [any]: any }, target_value: any): boolean
	for _,value in input do
		if target_value then
			return true
		end
	end
	
	return false
end