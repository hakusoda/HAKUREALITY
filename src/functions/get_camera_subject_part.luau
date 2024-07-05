--!strict
return function(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Humanoid") then
		return instance.RootPart
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart
	end
	
	return nil
end