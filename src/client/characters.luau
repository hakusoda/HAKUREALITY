--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")

local client = script.Parent
local root = client.Parent
local functions = root.functions
local local_player = Players.LocalPlayer :: Player
local locally_created_event = Instance.new("BindableEvent")

local types = require(client.types)
local constants = require(root.constants)
local get_camera = require(functions.get_camera)
local cleanup_instances = require(functions.cleanup_instances)
local cleanup_connections = require(functions.cleanup_connections)

local module = {
	items = {} :: { [Player]: types.Character }
}

function destroy_animation_track(track: AnimationTrack)
	track:Stop(0)
	track:Destroy()
end

function module.create(player: Player, model: Model): types.Character?
	local player_is_self = player == local_player
	if model:GetAttribute(constants.SETUP_ATTRIBUTE) or (player_is_self and VRService.VREnabled) then
		local existing = module.items[player]
		local character: types.Character = existing or {
			model = model,
			is_dead = false,
			cframes = table.create(4),
			kinematics = {},
			connections = {},
			last_cframes = table.create(4)
		}
		local connections = character.connections
		if character.model ~= model or not existing then
			if existing then
				character.is_dead = false
				
				table.clear(character.cframes)
				table.clear(character.last_cframes)
				cleanup_instances(character.kinematics)
				cleanup_connections(connections)

				character.humanoid, character.left_foot, character.right_foot, character.waist_motor = nil
			else
				warn(`[HAKUREALITY]: now handling {player} 👍`)
			end
			character.model = model

			local listen_for_children: (Instance) -> ()
			local function handle_child(child: Instance)
				if child:IsA("BasePart") then
					if player_is_self and child.Name == "Head" then
						-- we reduce the size of the head here to reduce the chance of Layered Clothing blocking the user's view.
						-- normally, you would adjust the HeadScale object, but it doesn't appear to work on the client.
						child.Size = Vector3.one / 10
						child.Transparency = 1

						local neck = child:FindFirstChild("Neck")
						if neck and neck:IsA("Motor6D") then
							neck.C0 *= CFrame.new(0, -1, 0)
						end
					elseif child.Name == "LowerTorso" then
						listen_for_children(child)
					elseif child.Name == "HumanoidRootPart" then
						listen_for_children(child)
					end
				elseif child:IsA("Accessory") then
					if player_is_self then
						local kind = child.AccessoryType
						if 
							kind == Enum.AccessoryType.Face or
							kind == Enum.AccessoryType.Hair or
							kind == Enum.AccessoryType.Hat
						then
							Debris:AddItem(child, 0)
						end
					end
				elseif child:IsA("Humanoid") then
					character.humanoid = child
					listen_for_children(child)
					if player_is_self then
						local animator = child:FindFirstChildWhichIsA("Animator")
						if animator then
							if not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE) then
								for _,track in animator:GetPlayingAnimationTracks() do
									destroy_animation_track(track)
								end
							end
							table.insert(connections, animator.AnimationPlayed:Connect(function(track)
								if not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE) then
									destroy_animation_track(track)
								end
							end))
						end
						get_camera().CameraSubject = child

						table.insert(connections, child:GetPropertyChangedSignal("AutoRotate"):Connect(function()
							child.AutoRotate = false
						end))
						
						-- animations played via Humanoid:LoadAnimation are not received by Animator.AnimationPlayed
						table.insert(connections, ((child :: any) :: Animator).AnimationPlayed:Connect(function(track)
							if not player:GetAttribute(constants.DISABLE_IK_ATTRIBUTE) then
								destroy_animation_track(track)
							end
						end))
						
						child.Died:Once(function()
							character.is_dead = true
							table.clear(character.cframes)
							table.clear(character.last_cframes)
							cleanup_instances(character.kinematics, true)
							cleanup_connections(connections)
							
							for _,instance in model:GetDescendants() do
								if instance:IsA("Constraint") and instance:GetAttribute("IS_HAKUREALITY_INSTANCE") then
									instance.Enabled = false
									instance:Destroy()
								end
							end
							
							character.humanoid, character.left_foot, character.right_foot, character.waist_motor = nil
						end)
					end
				elseif child:IsA("IKControl") then
					local kinematic: types.CharacterKinematic = {
						control = child
					}
					character.kinematics[child.Name] = kinematic
					
					local function handle_target(instance: Instance)
						if instance:IsA("Attachment") then
							kinematic.control_target = instance
							kinematic.control_target_identity = child:GetAttribute("offset")
						end
					end
					
					local target = child.Target
					if target then
						handle_target(target)
					else
						table.insert(connections, child:GetPropertyChangedSignal("Target"):Once(handle_target))
					end
				elseif child:IsA("Motor6D") and child.Name == "Root" then
					character.waist_motor = child
				elseif child:IsA("Attachment") then
					if child.Name == "LeftFoot" then
						character.left_foot = child
					elseif child.Name == "RightFoot" then
						character.right_foot = child
					end
				end
			end

			listen_for_children = function(parent: Instance)
				for _,child in parent:GetChildren() do
					handle_child(child)
				end
				table.insert(connections, parent.ChildAdded:Connect(handle_child))
			end
			listen_for_children(model)
		end
		module.items[player] = character

		locally_created_event:Fire()
		return character
	end
	return nil
end

local user_cframes = Enum.UserCFrame:GetEnumItems()
function module.update(character: types.Character, replication_alpha: number?)
	for _,kind in user_cframes do
		local index = kind.Value + 1
		local kinematic = character.kinematics[kind.Name]
		local prev_cframe = character.last_cframes[index]
		local raw_cframe = character.cframes[index]
		if raw_cframe then
			local final_cframe = prev_cframe and prev_cframe:Lerp(raw_cframe, replication_alpha or 1) or raw_cframe
			if kinematic then
				local control_target = kinematic.control_target
				if control_target then
					local control_target_identity = kinematic.control_target_identity
					if control_target_identity then
						control_target.CFrame = control_target_identity * final_cframe
					else
						control_target.CFrame = final_cframe
					end
				end
			end
			if kind == Enum.UserCFrame.Head then
				-- adjusts ground height to account for head position on the Y axis
				local waist = character.waist_motor
				if waist then
					waist.C0 = CFrame.new(0, math.clamp(final_cframe.Y, -0.75, 0) - 1, 0)
				end
				
				-- bends legs into an L shape if the user is physically crouching
				local left_foot, right_foot = character.left_foot, character.right_foot
				if left_foot or right_foot then
					local alpha = 1 - (math.clamp(final_cframe.Y, -0.75, -0.65) + 0.75) / 0.1
					if left_foot then
						left_foot.CFrame = CFrame.new(-0.5, -3, 0):Lerp(CFrame.new(-0.5, -2.5, 0.75) * CFrame.Angles(-math.pi / 2, 0, 0), alpha)
					end
					if right_foot then
						right_foot.CFrame = CFrame.new(0.5, -3, 0):Lerp(CFrame.new(0.5, -2.5, 0.75), alpha)
					end
				end
			end
		end
	end
end

-- local character is updated pre-render in client script
function module.update_others(replication_alpha: number?)
	for player, character in module.items do
		if player ~= local_player then
			module.update(character, replication_alpha)
		end
	end
end

function module.wait_for_local_character()
	local character = module.items[local_player]
	if not character then
		locally_created_event.Event:Wait()
		return module.items[local_player]
	end
	
	return character
end

return table.freeze(module)