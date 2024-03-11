--!strict
local Terrain = assert(workspace.Terrain)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local client = script.Parent
local root = client.Parent
local effects = root.effects
local functions = root.functions
local active_event = root.active_event
local cframe_replication = root.cframe_replication

local types = require(client.types)
local constants = require(root.constants)
local characters = require(client.characters)
local get_camera = require(functions.get_camera)
local show_notification = require(functions.show_notification)
local get_cframe_y_angle = require(functions.get_cframe_y_angle)
local create_instance_group = require(functions.create_instance_group)
local write_cframe_to_buffer = require(functions.write_cframe_to_buffer)
local generate_void_wireframe = require(functions.generate_void_wireframe)
local experimental_physical_backpack = require(client.experimental_physical_backpack)

local module = {
	active = VRService.VREnabled,
	local_rotation = 0,
	local_rotation_turning_offset = 0,
	local_rotation_turning_offset_target = 0,
	head_rotation_offset = 0,
	head_rotation_offset_target = 0,
	has_a_user_cframe_changed = false,
	photo_sensitivity_warning_active = false
}

local local_player = assert(Players.LocalPlayer)
local system_version = constants.VERSION
function set_character_rotation(character: types.Character, rotation: number)
	local root = character.model.PrimaryPart
	if root then
		local humanoid = character.humanoid
		if not humanoid or (not humanoid.SeatPart and not humanoid.PlatformStand) then
			root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, rotation, 0)
		end
	end
end

if module.active then
	-- tell the server we're in virtual reality
	active_event:FireServer()
	
	task.defer(function()
		-- surely there's a better way of doing this...
		local character = characters.wait_for_local_character()
		
		local blackspace_cframe = CFrame.new(0, 1000, 0)
		local warning_group, void_lighting, void_wireframe, void_interface = create_instance_group(
			effects.void_lighting,
			effects.void_wireframe,
			effects.void_interface
		)

		local comfort_ratings = {
			[-1] = "Unrated",
			[0] = "Comfortable",
			[1] = "Moderate",
			[2] = "Intense"
		}

		local photo_sensitivity_warning_active = constants.SHOW_PHOTOSENSITIVITY_WARNING
		module.photo_sensitivity_warning_active = photo_sensitivity_warning_active
		
		if photo_sensitivity_warning_active then
			void_lighting.Parent = Lighting

			local wireframe = void_wireframe.wireframe_part.wireframe
			generate_void_wireframe(wireframe)

			void_wireframe.Parent = Terrain

			local void_gui = void_interface.interface_part.gui
			void_gui.info.comfort.Text = `Comfort: {comfort_ratings[root:GetAttribute("comfortRating") or -1]}`
			void_gui.version.Text = system_version and
				`HAKUREALITY — Version {system_version}` or
				"HAKUREALITY — Unknown Version"
			void_gui.Parent = local_player.PlayerGui

			void_gui.acknowledge.Activated:Once(function()
				photo_sensitivity_warning_active, module.photo_sensitivity_warning_active = false, false

				local character_root_part = character.model.PrimaryPart
				if character_root_part then
					character_root_part.Anchored = false
				end

				local info = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
				TweenService:Create(void_lighting, info, { TintColor = Color3.new(1, 1, 1), Saturation = 0 }):Play()

				for _,i in void_gui:GetDescendants() do
					if i:IsA("GuiObject") then
						TweenService:Create(i, info, {
							Transparency = i:IsA("TextButton") and 1 or nil,
							TextTransparency = i:IsA("TextLabel") and 1 or nil,
							ImageTransparency = i:IsA("ImageLabel") and 1 or nil
						}):Play()
					end
				end

				task.spawn(function()
					local a = 5 * info.Time
					for i = 1, a do
						-- we have to reconstruct the wireframe after changing the transparency, as it doesn't automatically update the current wireframe.
						wireframe.Transparency = i / a
						generate_void_wireframe(wireframe)
						task.wait(0.1)
					end
				end)
				task.delay(info.Time, function()
					warning_group.destroy_all()
					void_lighting, void_wireframe, void_interface = nil
				end)
			end)

			void_interface.Parent = Terrain
		else
			warning_group.destroy_all()
			void_lighting, void_wireframe, void_interface = nil
		end

		local local_rotation = 0
		local local_rotation_turning_offset = 0
		local local_rotation_turning_offset_target = 0
		local head_rotation_offset = 0
		local head_rotation_offset_target = 0

		local has_a_user_cframe_changed = false
		RunService.PreSimulation:Connect(function(delta_time)
			local is_dead = character.is_dead
			if not experimental_physical_backpack.is_open and not is_dead and not photo_sensitivity_warning_active then
				local rotate = 0
				for _,input: InputObject in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
					if input.KeyCode == Enum.KeyCode.Thumbstick2 then
						rotate = input.Position.X
					end
				end

				local_rotation -= math.pi * rotate * 1.5 * delta_time
				module.local_rotation = local_rotation
			end

			if not is_dead and not photo_sensitivity_warning_active then
				-- TODO: store the primarypart in a field
				local root = character.model.PrimaryPart
				if root then
					set_character_rotation(character, local_rotation + local_rotation_turning_offset)

					local humanoid = character.humanoid
					if humanoid then
						local is_jump_down = UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
						local move_direction = Vector3.zero
						for _,input: InputObject in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
							if input.KeyCode == Enum.KeyCode.Thumbstick1 then
								move_direction = input.Position
							end
						end

						local head_direction = root.CFrame * VRService:GetUserCFrame(Enum.UserCFrame.Head).Rotation * CFrame.Angles(0, head_rotation_offset_target, 0)
						move_direction = move_direction.Y * head_direction.LookVector + move_direction.X * head_direction.RightVector

						humanoid.Jump = is_jump_down
						humanoid:Move(move_direction, false)
					end
				end
			end
		end)

		local last_user_cframes: { [Enum.UserCFrame]: CFrame } = {}
		VRService.UserCFrameChanged:Connect(function(kind, value)
			if not has_a_user_cframe_changed then
				-- we only replicate current positions if they have significantly changed since the last replication.
				local last = last_user_cframes[kind]
				if not last or not value.Position:FuzzyEq(last.Position, 0.1) or value.LookVector:Dot(last.LookVector) < 0.95 then
					has_a_user_cframe_changed, module.has_a_user_cframe_changed = true, true
					last_user_cframes[kind] = value
				end
			end
			if kind == Enum.UserCFrame.Head then
				-- rotate character with physical head, experimental.
				local head_yaw = get_cframe_y_angle(value)
				if not photo_sensitivity_warning_active and CFrame.Angles(0, head_yaw + head_rotation_offset_target, 0).LookVector:Dot(-Vector3.zAxis) < 0.75 then
					local_rotation_turning_offset_target = head_yaw
					head_rotation_offset_target = -head_yaw
					
					module.head_rotation_offset_target = head_rotation_offset_target
					module.local_rotation_turning_offset_target = local_rotation_turning_offset_target
				end
			end
			character.cframes[kind.Value + 1] = value
		end)

		local function handle_user_input(input: InputObject, game_processed: boolean)
			if not game_processed and (input.KeyCode == Enum.KeyCode.ButtonR3 or input.KeyCode == Enum.KeyCode.Minus) then
				if input.UserInputState == Enum.UserInputState.Begin then
					experimental_physical_backpack.open()
				elseif experimental_physical_backpack.is_open then
					experimental_physical_backpack.close()
				end
			end
		end
		UserInputService.InputBegan:Connect(handle_user_input)
		UserInputService.InputEnded:Connect(handle_user_input)

		local last_body_rotation = CFrame.identity
		RunService.PreRender:Connect(function(delta_time: number)
			-- TODO: improve determination of subject
			local camera = get_camera()
			if photo_sensitivity_warning_active then
				local pos = blackspace_cframe
				camera.Focus = pos
				camera.CFrame = pos
				camera.CameraType = Enum.CameraType.Scriptable

				local character_root_part = character.model.PrimaryPart
				if character_root_part then
					character_root_part.Anchored = true
				end
			else
				local subject = camera.CameraSubject
				if subject then
					local subject_root_part = subject:IsA("Humanoid") and subject.RootPart or subject.Parent.PrimaryPart
					if subject_root_part then
						local delta_time_doubled = delta_time * 2
						if local_rotation_turning_offset ~= local_rotation_turning_offset_target then
							if local_rotation_turning_offset > local_rotation_turning_offset_target then
								local_rotation_turning_offset = math.max(local_rotation_turning_offset - delta_time_doubled, local_rotation_turning_offset_target)
							else
								local_rotation_turning_offset = math.min(local_rotation_turning_offset + delta_time_doubled, local_rotation_turning_offset_target)
							end
							module.local_rotation_turning_offset = local_rotation_turning_offset
							
							set_character_rotation(character, local_rotation + local_rotation_turning_offset)
						end

						if head_rotation_offset ~= head_rotation_offset_target then
							if head_rotation_offset > head_rotation_offset_target then
								head_rotation_offset = math.max(head_rotation_offset - delta_time_doubled, head_rotation_offset_target)
							else
								head_rotation_offset = math.min(head_rotation_offset + delta_time_doubled, head_rotation_offset_target)
							end
							module.head_rotation_offset = head_rotation_offset
						end

						-- TODO: adjust for avatar scale
						local is_dead = character.is_dead
						local head_rotation = CFrame.Angles(0, head_rotation_offset, 0)
						local body_rotation = is_dead and last_body_rotation or CFrame.Angles(0, get_cframe_y_angle(subject_root_part.CFrame), 0)
						local camera_cframe = is_dead and
							CFrame.new(camera.CFrame.Position) * body_rotation * head_rotation or
							CFrame.new(subject_root_part.Position) * body_rotation * CFrame.new(0, 1.5, 0) * head_rotation
						camera.Focus = camera_cframe
						camera.CFrame = camera_cframe
						camera.CameraType = Enum.CameraType.Scriptable

						last_body_rotation = body_rotation

						characters.update(character)
					end
				end

				experimental_physical_backpack.render()
			end

			if void_interface then
				void_interface:PivotTo(CFrame.new(camera.CFrame.Position) - Vector3.zAxis * 24)
			end

			if void_wireframe then
				void_wireframe:PivotTo(CFrame.new(camera.CFrame.Position))
			end
		end)

		local user_cframe_enum_items = Enum.UserCFrame:GetEnumItems()
		task.defer(function()
			-- TODO: improve
			local REPLICATION_RATE = 1 / constants.REPLICATION_RATE
			while task.wait(REPLICATION_RATE) do
				if not character.is_dead and has_a_user_cframe_changed and #Players:GetPlayers() > 1 then
					has_a_user_cframe_changed, module.has_a_user_cframe_changed = false, false
					
					local kinematics = character.kinematics

					local positions: { buffer } = table.create(4)
					for _,kind in user_cframe_enum_items do
						if kinematics[kind.Name] then
							local new_buffer = buffer.create(19)
							write_cframe_to_buffer(new_buffer, 0, VRService:GetUserCFrame(kind))
							
							positions[kind.Value + 1] = new_buffer
						end
					end

					cframe_replication:FireServer(positions)
				end
			end
		end)
		
		task.defer(function()
			while task.wait(5) do
				local not_tracking = {}
				for _,kind in user_cframe_enum_items do
					if kind ~= Enum.UserCFrame.Floor then
						local cframe = character.cframes[kind.Value + 1]
						if not cframe or cframe == CFrame.identity then
							table.insert(not_tracking, kind.Name)
						end
					end
				end
				
				local not_tracking_amount = #not_tracking
				if not_tracking_amount > 0 then
					show_notification(`oh noes! your {table.concat(not_tracking, ", ")} {not_tracking_amount > 1 and "aren" or "isn"}'t tracking!`)
				end
			end
		end)
		VRService.AutomaticScaling = Enum.VRScaling.World

		task.defer(StarterGui.SetCore, StarterGui, "VREnableControllerModels", false)
		task.defer(RunService.UnbindFromRenderStep, RunService, "ControlScriptRenderstep")
	end)
end

return module