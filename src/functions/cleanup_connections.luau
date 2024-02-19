--!strict
return function(connections: { [any]: RBXScriptConnection? })
	for _,connection in connections do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end