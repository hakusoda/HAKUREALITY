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

local module = { last_replicated_at = 0 }

local local_player = Players.LocalPlayer
local last_replicated_at = 0
RunService.PreAnimation:Connect(function()
	-- TODO: improve position lerping
	local alpha = math.min(os.clock() - last_replicated_at, 0.1) / 0.1
	characters.update_others(alpha)
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
		table.clear(character.last_cframes)
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
	last_replicated_at = os.clock()
	module.last_replicated_at = last_replicated_at
	for _,yeah in positions do
		local player: Player, values = table.unpack(yeah)
		if player ~= local_player then
			local character = characters.items[player]
			if character then
				local last_cframes = character.last_cframes
				table.clear(last_cframes)

				local cframes = character.cframes
				table.move(cframes, 1, #cframes, 1, last_cframes)

				character.cframes = values
			end
		end
	end
end)

return module