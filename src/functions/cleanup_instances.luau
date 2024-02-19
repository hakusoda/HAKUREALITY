--!strict
function cleanup_instances(instances: { [any]: any }, clear_everything: boolean?)
	local is_frozen = table.isfrozen(instances)
	for key, instance in instances do
		if typeof(instance) == "Instance" then
			if instance:IsA("IKControl") then
				instance.Enabled = false
			end
			instance:Destroy()
			
			if not is_frozen and not clear_everything then
				instances[key] = nil
			end
		elseif typeof(instance) == "table" then
			cleanup_instances(instance, clear_everything)
		end
	end
	
	if not is_frozen and clear_everything then
		table.clear(instances)
	end
end

return cleanup_instances