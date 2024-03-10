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
local system_version = constants.VERSION
local display_version = system_version and `v0.0.{system_version}` or "Unknown Version"
function render_character(player: Player, character: types.Character)
	local display_name = player.DisplayName
	Iris.Tree({`{display_name}{player == local_player and " (You)" or ""}`})
		Iris.Text({`model: {character.model:GetFullName()}`})
		Iris.Text({`is_dead: {character.is_dead}`})
		Iris.Text({`humanoid: {character.humanoid and character.humanoid:GetFullName()}`})
		Iris.Text({`left_foot: {character.left_foot and character.left_foot:GetFullName()}`})
		Iris.Text({`right_foot: {character.right_foot and character.right_foot:GetFullName()}`})
		Iris.Text({`waist_motor: {character.waist_motor and character.waist_motor:GetFullName()}`})
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
		if Iris.Button({`Reset {display_name}`}).clicked() then
			characters.create(player, character.model)
		end
	Iris.End()
end

Iris:Connect(function()
	if module.visible then
		local is_backpack_open = experimental_physical_backpack.is_open
		Iris.Window({`HAKUREALITY Debugger — {display_version}` :: any, nil, nil, nil, true})
			Iris.Text({`FPS: {render_counter.value}`})
			Iris.Text({`Package: {package_id} (v{system_version})`})
			Iris.Text({`Debugger Renderer: Iris{Iris.Internal._version}`})
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
				Iris.Tree({`local_rotation: {local_handler.local_rotation}`})
					Iris.Text({`_turning_offset: {local_handler.local_rotation_turning_offset}`})
					Iris.Text({`_turning_offset_target: {local_handler.local_rotation_turning_offset_target}`})
				Iris.End()
				Iris.Tree({`head_rotation_offset: {local_handler.head_rotation_offset}`})
					Iris.Text({`_target: {local_handler.head_rotation_offset_target}`})
				Iris.End()
				Iris.Text({`has_a_user_cframe_changed: {local_handler.has_a_user_cframe_changed}`})
				Iris.Text({`photo_sensitivity_warning_active: {local_handler.photo_sensitivity_warning_active}`})
			Iris.End()
			Iris.Tree({"player_handler"})
				Iris.Text({`last_replicated_at: {math.floor((os.clock() - player_handler.last_replicated_at) * 100) / 100} seconds ago`})
			Iris.End()
			Iris.Tree({"experimental_physical_backpack"})
				Iris.Text({`open: {is_backpack_open}`})
				if is_backpack_open then
					local gui = assert(experimental_physical_backpack.current_gui)
					Iris.Text({`items: {#gui.items}`})
					Iris.Text({`position: {gui.position}`})
					Iris.Text({`current_item: {gui.current_item}`})
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