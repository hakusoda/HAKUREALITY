--!strict
function clean_instance(instance: Instance)
	if instance:IsA("LuaSourceContainer") or instance:IsA("ValueBase") or instance:IsA("ParticleEmitter") or instance:IsA("BaseRemoteEvent") or instance:IsA("RemoteFunction") or instance:IsA("BindableEvent") or instance:IsA("BindableFunction") or instance:IsA("Weld") or instance:IsA("Constraint") or instance:IsA("Sound") or instance:IsA("GuiBase") then
		return instance:Destroy()
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanQuery = false
		instance.CanTouch = false
		instance.CanCollide = false
	end
	
	for _,name in instance:GetTags() do
		instance:RemoveTag(name)
	end
	for name,_ in instance:GetAttributes() do
		instance:SetAttribute(name, nil)
	end
end

return function(instance: Model, size: UDim2): ViewportFrame
	local new_instance = instance:Clone()
	clean_instance(new_instance)
	
	for _,instance in new_instance:GetDescendants() do
		clean_instance(instance)
	end
	
	local extents = new_instance:GetExtentsSize()
	local distance = math.max(extents.X, extents.Y)
	
	local viewport = Instance.new("ViewportFrame")
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.Angles(0, math.pi / 5, 0) * CFrame.Angles(-math.pi / 8, 0, 0) * CFrame.new(0, 0, distance)
	camera.Parent = viewport
	
	new_instance:PivotTo(CFrame.identity)
	new_instance.Parent = viewport
	
	viewport.Size = size
	viewport.Transparency = 1
	viewport.CurrentCamera = camera
	
	return viewport
end