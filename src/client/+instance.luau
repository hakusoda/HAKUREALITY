--!strict
local Terrain = workspace.Terrain
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent

local sync = root.sync
local events = root.events
local effects = root.effects
local package = root:FindFirstChild("PackageLink")
local functions = root.functions
local local_player = Players.LocalPlayer

local types = require(script.types)
local constants = require(root.constants)
local characters = require(script.characters)
local get_camera = require(functions.get_camera)
local cleanup_instances = require(functions.cleanup_instances)
local cleanup_connections = require(functions.cleanup_connections)
local create_instance_group = require(functions.create_instance_group)
local generate_void_wireframe = require(functions.generate_void_wireframe)
local experimental_physical_backpack = require(script.experimental_physical_backpack)

local REPLICATION_RATE = 1 / (root:GetAttribute("replicationRate") or 20)

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

sync.OnClientEvent:Connect(function(positions: {{any}})
	last_replicated_at = os.clock()
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

-- returns how far the cframe is rotated about the y axis
-- based on https://github.com/AxisAngles/Math-Gems/blob/main/CFrameAngleAboutCardinalAxis.lua
function get_cframe_y_angle(cframe: CFrame)
	local _,_,_,xx, _,zx, _,_,_,xz, _,zz = cframe:GetComponents()
	return math.atan2(zx - xz, xx + zz)
end

function set_character_rotation(character: types.Character, rotation: number)
	local root = character.model.PrimaryPart
	if root then
		local humanoid = character.humanoid
		if not humanoid or (not humanoid.SeatPart and not humanoid.PlatformStand) then
			root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, rotation, 0)
		end
	end
end

if VRService.VREnabled then
	-- tell the server we're in virtual reality
	events:FireServer(0)
	
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
	
	local photo_sensitivity_warning_active = root:GetAttribute("showPhotosensitivityWarning") :: boolean
	if photo_sensitivity_warning_active then
		void_lighting.Parent = Lighting
		
		local wireframe = void_wireframe.wireframe_part.wireframe
		generate_void_wireframe(wireframe)
		
		void_wireframe.Parent = Terrain
		
		local void_gui = void_interface.interface_part.gui
		void_gui.info.comfort.Text = `Comfort: {comfort_ratings[root:GetAttribute("comfortRating") or -1]}`
		void_gui.version.Text = package and
			`HAKUREALITY — Version {package.VersionNumber}` or
			"HAKUREALITY — Unknown Version"
		void_gui.Parent = local_player.PlayerGui
		
		void_gui.acknowledge.Activated:Once(function()
			photo_sensitivity_warning_active = false
			
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
				has_a_user_cframe_changed = true
				last_user_cframes[kind] = value
			end
		end
		if kind == Enum.UserCFrame.Head then
			-- rotate character with physical head, experimental.
			local head_yaw = get_cframe_y_angle(value)
			if not photo_sensitivity_warning_active and CFrame.Angles(0, head_yaw + head_rotation_offset_target, 0).LookVector:Dot(-Vector3.zAxis) < 0.75 then
				local_rotation_turning_offset_target = head_yaw
				head_rotation_offset_target = -head_yaw
			end
		end
		character.cframes[kind.Value + 1] = value
	end)
	
	function handle_user_input(input: InputObject, game_processed: boolean)
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
						set_character_rotation(character, local_rotation + local_rotation_turning_offset)
					end

					if head_rotation_offset ~= head_rotation_offset_target then
						if head_rotation_offset > head_rotation_offset_target then
							head_rotation_offset = math.max(head_rotation_offset - delta_time_doubled, head_rotation_offset_target)
						else
							head_rotation_offset = math.min(head_rotation_offset + delta_time_doubled, head_rotation_offset_target)
						end
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

					characters.update(character, 1)
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
		while task.wait(REPLICATION_RATE) do
			if not character.is_dead and has_a_user_cframe_changed then
				local kinematics = character.kinematics
				
				local positions: { CFrame } = table.create(4)
				for _,kind in user_cframe_enum_items do
					if kinematics[kind.Name] then
						positions[kind.Value + 1] = VRService:GetUserCFrame(kind)
					end
				end

				sync:FireServer(positions)
			end
		end
	end)
	VRService.AutomaticScaling = Enum.VRScaling.World
	
	task.defer(StarterGui.SetCore, StarterGui, "VREnableControllerModels", false)
	task.defer(RunService.UnbindFromRenderStep, RunService, "ControlScriptRenderstep")
end

warn(`[HAKUREALITY]: fully initialised, yummy! currently on version {package and package.VersionNumber or "😓❓"}, was loaded from {root:GetAttribute("was_imported_via_loader") and "the require-based loader" or package and package.PackageId == "rbxassetid://15429676683" and "HAKUMI's public package" or "a third-party package, not maintained by HAKUMI" or "an unknown source, not maintained by HAKUMI"}.`)
warn("[HAKUREALITY]: hello, console dweller, if you witness any \"flaws\" with players in virtual reality, pretty please report it directly to HAKUMI!")