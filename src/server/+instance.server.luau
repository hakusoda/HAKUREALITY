--!strict
local Players = game:GetService("Players")

local root = script.Parent
local package = root:FindFirstChild("PackageLink")
local functions = root.functions
local kinematics = script.kinematics
local active_event = root.active_event
local cframe_replication = root.cframe_replication
local server_debug_events = root.server_debug_events

local constants = require(root.constants)
local mark_instance = require(functions.mark_instance)
local cleanup_instances = require(functions.cleanup_instances)
local create_chat_command = require(functions.create_chat_command)

local REPLICATION_RATE = 1 / constants.REPLICATION_RATE
function get_head_scale(model: Model): number
	local scale = model:FindFirstChild("HeadScale", true)
	if scale and scale:IsA("NumberValue") then
		return scale.Value
	end
	return 1
end

local players_with_debugger: { [Player]: boolean } = {}

local all_kinematics = kinematics:GetChildren()
local all_kinematics_length = #all_kinematics
for _,kinematic in all_kinematics do
	if kinematic:IsA("IKControl") then
		local name = kinematic.Name
		if name == "Head" or string.find(name, "Hand") then
			kinematic.SmoothTime = REPLICATION_RATE
		end
	end
end

function setup_character(player: Player, model: Model)
	local humanoid = assert(model:FindFirstChildWhichIsA("Humanoid"), `{model} is missing a Humanoid... 😥`)
	
	local root = model.PrimaryPart
	local head_scale = get_head_scale(model)
	
	local instances = table.create(all_kinematics_length * 2)
	for _,child in all_kinematics do
		if child:IsA("IKControl") then
			local target = Instance.new("Attachment")
			target.Name = child.Name
			
			if child.Name == "Head" and root then
				target.CFrame = CFrame.new(0, root.Size.Y / 2 + head_scale / 2, 0)
			else
				target.CFrame = child:GetAttribute("offset") or CFrame.identity
			end
			mark_instance(target)
			target.Parent = root
			
			local clone = child:Clone()
			clone.Target = target
			clone.Enabled = not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE)
			clone.ChainRoot = model:FindFirstChild(clone:GetAttribute("start"))
			clone.EndEffector = model:FindFirstChild(clone.Name)
			
			mark_instance(clone)
			clone.Parent = humanoid
			
			table.insert(instances, target)
			table.insert(instances, clone)
		elseif child:IsA("Constraint") then
			local origin = model:FindFirstChild(child:GetAttribute("origin"))
			local second = model:FindFirstChild(child.Name)
			if origin and second then
				local target = child:GetAttribute("target")
				
				local clone = child:Clone()
				clone.Attachment0 = origin:FindFirstChild(target)
				clone.Attachment1 = second:FindFirstChild(target)
				
				mark_instance(clone)
				clone.Parent = origin
				
				table.insert(instances, clone)
			end
		end
	end
	
	model:SetAttribute(constants.SETUP_ATTRIBUTE, true)
	
	humanoid.AutoRotate = false
	humanoid.Died:Once(function()
		cleanup_instances(instances)
	end)
	model.Destroying:Once(function()
		cleanup_instances(instances)
	end)
	
	if not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE) then
		local animate = model:FindFirstChild("Animate")
		if animate and animate:IsA("LocalScript") then
			animate:Destroy()
		end
	end
end

function handle_player(player: Player)
	warn(`[HAKUREALITY]: now handling {player} as they claim to be in virtual reality 👍`)
	local character = player.Character
	if character then
		setup_character(player, character)
	end
	
	player.CharacterAdded:Connect(function(model)
		setup_character(player, model)
	end)
	
	player:GetAttributeChangedSignal(constants.DISABLE_IK_ATTRIBUTE):Connect(function()
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				for _,child in humanoid:GetChildren() do
					if child:IsA("IKControl") then
						child.Enabled = not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE)
					end
				end
			end
		end
	end)
end

local active_vr_players: { [Player]: boolean } = {}
local player_user_cframes: { [Player]: { buffer } } = {}
Players.PlayerRemoving:Connect(function(player)
	active_vr_players[player],
		player_user_cframes[player],
		players_with_debugger[player] = nil
end)

active_event.OnServerEvent:Connect(function(player)
	if not active_vr_players[player] then
		player:SetAttribute("isInVirtualReality", true)
		
		active_vr_players[player] = true
		handle_player(player)
	end
end)

local last_replication_at = 0
cframe_replication.OnServerEvent:Connect(function(player, user_cframes: { buffer })
	player_user_cframes[player] = user_cframes
	
	local current_time = os.clock()
	if current_time - last_replication_at > REPLICATION_RATE then
		last_replication_at = current_time

		local replication_items = {}
		for player, values in player_user_cframes do
			if typeof(values) ~= "table" then
				print("rejecting values")
			end
			for index, value in values do
				if index < 1 or index > 4 or typeof(value) ~= "buffer" then
					print(`rejecting values.{index}`)
				end
			end
			table.insert(replication_items, { player, values :: any })
		end
		
		table.clear(player_user_cframes)
		cframe_replication:FireAllClients(replication_items)
	end
end)

--local user_creator_id = game.CreatorType == Enum.CreatorType.User and game.CreatorId or nil
server_debug_events.OnServerEvent:Connect(function(player, event: number)
	if event == 0 then
		--local user_id = player.UserId
		local has_debugger = players_with_debugger[player]
		local condition = false--user_id == user_creator_id or user_id == 373020309
		if condition then
			players_with_debugger[player] = has_debugger and nil :: any or true
		else
			server_debug_events:FireClient(player, 0)
		end
	end
end)

create_chat_command("/hakudebug")
create_chat_command("/hakudebugserver")

--[[task.defer(function()
	while task.wait(5) do
		local new_buffer = buffer.create(0)
		for player,_ in players_with_debugger do
			server_debug_replication:FireClient(player, new_buffer)
		end
	end
end)]]

warn(`[HAKUREALITY]: greetings & salutations from version {package and package.VersionNumber or "😓❓"}!`)