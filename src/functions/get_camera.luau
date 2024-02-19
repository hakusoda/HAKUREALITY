--!strict
return function()
	return assert(workspace.CurrentCamera, "Local player camera is missing (workspace.CurrentCamera is nil)")
end