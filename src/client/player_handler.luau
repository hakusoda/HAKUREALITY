--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local client = script.Parent
local root = client.Parent
local functions = root.functions
local cframe_replication = root.cframe_replication

local constants = require(root.constants)
local characters = require(client.characters)
local cleanup_instances = require(functions.cleanup_instances)
local cleanup_connections = require(functions.cleanup_connections)
local read_cframe_from_buffer = require(functions.read_cframe_from_buffer)

local module = { last_replicated_at = 0 }

local local_player = Players.LocalPlayer
RunService.PreAnimation:Connect(function()
	characters.update_others()
end)

function handle_character(player: Player, model: Model)
	if not characters.create(player, model) then
		model:GetAttributeChangedSignal(constants.SETUP_ATTRIBUTE):Once(function()
			characters.create(player, model)
		end)
	end
end

function handle_player(player: Player)
	local character = player.Character
	if character then
		handle_character(player, character)
	end

	player.CharacterAdded:Connect(function(character)
		handle_character(player, character)
	end)
end

for _,player in Players:GetPlayers() do
	handle_player(player)
end
Players.PlayerAdded:Connect(handle_player)
Players.PlayerRemoving:Connect(function(player)
	local character = characters.items[player]
	if character then
		table.clear(character.cframes)
		cleanup_instances(character.kinematics, true)
		cleanup_connections(character.connections)

		character.humanoid, character.left_foot, character.right_foot, character.waist_motor = nil
	end

	characters.items[player] = nil
	if character then
		warn(`[HAKUREALITY]: cleaned up {player}'s remains (they left the server) 🙂`)
	end
end)

cframe_replication.OnClientEvent:Connect(function(positions: {{any}})
	module.last_replicated_at = os.clock()
	for _,yeah in positions do
		local player: Player, values: { buffer } = table.unpack(yeah)
		if player ~= local_player then
			local character = characters.items[player]
			if character then
				local decompressed_values = {}
				for index, cframe_buffer in values do
					decompressed_values[index] = read_cframe_from_buffer(cframe_buffer, 0)
				end
				
				character.cframes = decompressed_values
			end
		end
	end
end)

return module