--!strict
local Players = game:GetService("Players")

local root = script.Parent
local sync = root.sync
local events = root.events
local package = root:FindFirstChild("PackageLink")
local functions = root.functions
local kinematics = script.kinematics

local constants = require(root.constants)
local mark_instance = require(functions.mark_instance)
local cleanup_instances = require(functions.cleanup_instances)

local REPLICATION_RATE = 1 / (root:GetAttribute("replicationRate") or 20)
function get_head_scale(model: Model): number
	local scale = model:FindFirstChild("HeadScale", true)
	if scale and scale:IsA("NumberValue") then
		return scale.Value
	end
	return 1
end

local all_kinematics = kinematics:GetChildren()
local all_kinematics_length = #all_kinematics
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
						child.Enabled = not player:GetAttribute("disableInverseKinematics")
					end
				end
			end
		end
	end)
end

local active_vr_players: { [Player]: boolean } = {}
local player_user_cframes: { [Player]: {CFrame} } = {}
Players.PlayerRemoving:Connect(function(player)
	active_vr_players[player] = nil
	player_user_cframes[player] = nil
end)

local lastSendTime = 0
events.OnServerEvent:Connect(function(player, event: number)
	if event == 0 then
		if not active_vr_players[player] then
			player:SetAttribute("isInVirtualReality", true)
			
			active_vr_players[player] = true
			handle_player(player)
		end
	end
end)

sync.OnServerEvent:Connect(function(player, positions: { CFrame })
	player_user_cframes[player] = positions
	if os.clock() - lastSendTime > REPLICATION_RATE then
		lastSendTime = os.clock()

		local positions = {}
		for player, values in player_user_cframes do
			table.insert(positions, {player, values :: any})
		end
		sync:FireAllClients(positions)
	end
end)

warn(`[HAKUREALITY]: greetings & salutations from version {package and package.VersionNumber or "😓❓"}!`)