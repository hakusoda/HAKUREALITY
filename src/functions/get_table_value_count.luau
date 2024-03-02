--!strict
return function(input: any): number
	if typeof(input) == "table" then
		local count = 0
		for _,_ in input do
			count += 1
		end
		
		return count
	end
	return 0
end