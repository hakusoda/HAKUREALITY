--!strict
type InstanceGroup = {
	destroy_all: () -> ()
}
return function<T...>(...: T...): (InstanceGroup, T...)
	local instances = {...}
	for _,instance in instances do
		if typeof(instance) == "Instance" then
			instance.Destroying:Once(function()
				local index = table.find(instances, instance)
				if index then
					table.remove(instances, index)
				end
			end)
		end
	end
	
	return table.freeze({
		destroy_all = function()
			if instances then
				for _,instance in instances do
					if typeof(instance) == "Instance" then
						instance:Destroy()
					end
				end
				table.clear(instances)
				instances = nil :: any
			end
		end
	}), ...
end