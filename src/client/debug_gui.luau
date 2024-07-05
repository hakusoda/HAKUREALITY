--!strict
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")

local client = script.Parent
local root = client.Parent
local functions = root.functions

local Iris = require(client.iris_instance)
local types = require(client.types)
local constants = require(root.constants)
local characters = require(client.characters)
local display_time = require(functions.display_time)
local local_handler = require(client.local_handler)
local player_handler = require(client.player_handler)
local create_fps_counter = require(functions.create_fps_counter)
local get_table_value_count = require(functions.get_table_value_count)
local experimental_physical_backpack = require(client.experimental_physical_backpack)

local user_cframes = Enum.UserCFrame:GetEnumItems()
local render_counter = create_fps_counter(RunService.PreRender)
local initial_visibility = false

local enabled_default = root:GetAttribute("enable_debug_default")
if (enabled_default == "vr_only" and VRService.VREnabled) or enabled_default then
	initial_visibility = true
end

local module = {
	visible = initial_visibility
}

local package = constants.PACKAGE
local package_id = package and package.PackageId
local local_player = assert(Players.LocalPlayer)
local display_version = constants.VERSION
local package_version = constants.PACKAGE_VERSION
function render_character(player: Player, character: types.Character)
	local display_name = player.DisplayName
	Iris.Tree({`{display_name}{player == local_player and " (You)" or ""}`})
		Iris.Text({`model: {character.model:GetFullName()}`})
		Iris.Text({`humanoid: {character.humanoid and character.humanoid:GetFullName()}`})
		Iris.Text({`left_foot: {character.left_foot and character.left_foot:GetFullName()}`})
		Iris.Text({`right_foot: {character.right_foot and character.right_foot:GetFullName()}`})
		Iris.Text({`waist_motor: {character.waist_motor and character.waist_motor:GetFullName()}`})
		Iris.Separator()
		Iris.Text({`is_dead: {character.is_dead}`})
		Iris.Text({`connections: {#character.connections}`})
		Iris.Separator()
		Iris.Tree({"cframes"})
			for _,kind in user_cframes do
				Iris.Text({`{kind.Name}: {character.cframes[kind.Value + 1]}`})
			end
		Iris.End()
		Iris.Tree({"kinematics"})
			for name, kinematic in character.kinematics do
				Iris.Tree({name})
					Iris.Text({`control: {kinematic.control:GetFullName()}`})
					Iris.Text({`control_target: {kinematic.control_target and kinematic.control_target:GetFullName()}`})
					Iris.Text({`control_target_identity: {kinematic.control_target_identity}`})
				Iris.End()
			end
		Iris.End()
		Iris.Separator()
		if Iris.Button({`Re-create {display_name}`}).clicked() then
			characters.create(player, character.model)
		end
	Iris.End()
end

function calculate_average_of_number_table(input: { [any]: number }): number
	local total = 0
	for _,value in input do
		total += value
	end
	
	return total / #input
end

Iris:Connect(function()
	if module.visible then
		local is_backpack_open = experimental_physical_backpack.is_open
		Iris.Window({`HAKUREALITY Debugger — {display_version}` :: any, nil, nil, nil, true})
			Iris.Text({`FPS: {render_counter.value}`})
			Iris.Text({`Package: {package_id} (r{package_version})`})
			Iris.Text({`Debugger Renderer: Iris{Iris.Internal._version}`})
			Iris.Text({`Default Visibility: {enabled_default}`})
			Iris.Separator()
			Iris.Tree({"constants"})
				for key, value in constants do
					Iris.Text({`{key}: {value}`})
				end
			Iris.End()
			Iris.Tree({`characters ({get_table_value_count(characters.items)})`})
				for player, character in characters.items do
					render_character(player, character)
				end
			Iris.End()
			Iris.Tree({"local_handler"})
				Iris.Text({`active: {local_handler.active}`})
				Iris.Text({`average_compression_time: {display_time(calculate_average_of_number_table(local_handler.average_compression_time))}`})
				Iris.Separator()
				Iris.Tree({`local_rotation: {local_handler.local_rotation}`})
					Iris.Text({`_turning_offset: {local_handler.local_rotation_turning_offset}`})
					Iris.Text({`_turning_offset_target: {local_handler.local_rotation_turning_offset_target}`})
				Iris.End()
				Iris.Tree({`head_rotation_offset: {local_handler.head_rotation_offset}`})
					Iris.Text({`_target: {local_handler.head_rotation_offset_target}`})
				Iris.End()
				Iris.Separator()
				Iris.Text({`has_a_user_cframe_changed: {local_handler.has_a_user_cframe_changed}`})
				Iris.Text({`photo_sensitivity_warning_active: {local_handler.photo_sensitivity_warning_active}`})
			Iris.End()
			Iris.Tree({"player_handler"})
				Iris.Text({`last_replicated_at: {display_time(os.clock() - player_handler.last_replicated_at)} ago`})
				Iris.Text({`average_decompression_time: {display_time(calculate_average_of_number_table(player_handler.average_decompression_time))}`})
			Iris.End()
			Iris.Tree({"experimental_physical_backpack"})
				Iris.Text({`open: {is_backpack_open}`})
				if is_backpack_open then
					local gui = assert(experimental_physical_backpack.current_gui)
					Iris.Text({`gui: {gui.gui:GetFullName()}`})
					Iris.Text({`part: {gui.part:GetFullName()}`})
					Iris.Tree({`items ({#gui.items})`})
						for index, item in gui.items do
							Iris.Tree({`item {index}`})
								Iris.Text({`instance: {item.instance.Name}`})
								Iris.Separator()
								Iris.Text({`button: {item.button:GetFullName()}`})
								Iris.Text({`button_image: {item.button_image:GetFullName()} ({item.button_image.ClassName})`})
								Iris.Text({`button_stroke: {item.button_stroke:GetFullName()}`})
								Iris.Separator()
								Iris.Text({`hover_alpha: {item.hover_alpha}`})
								Iris.Text({`hover_interface: {item.hover_interface and item.hover_interface.instance:GetFullName() or nil}`})
							Iris.End()
						end
					Iris.End()
					Iris.Text({`position: {gui.position}`})
					Iris.Text({`hover_alpha: {gui.hover_alpha}`})
					Iris.Separator()
					Iris.Text({`current_item: {gui.current_item}`})
					Iris.Text({`last_hover_item: {gui.last_hover_item}`})
					Iris.Separator()
					Iris.Text({`name_bubble: {gui.name_bubble:GetFullName()}`})
					Iris.Text({`name_bubble_alpha: {gui.name_bubble_alpha}`})
				end
			Iris.End()
			Iris.Separator()
			Iris.Tree({"a warning to those who trespass..."})
				Iris.Cat()
			Iris.End()
		Iris.End()
	end
end)

return module