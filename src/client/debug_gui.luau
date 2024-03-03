--!strict
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")

local client = script.Parent
local root = client.Parent
local package = root:FindFirstChild("PackageLink")
local functions = root.functions

local characters = require(client.characters)
local create_fps_counter = require(functions.create_fps_counter)
local get_table_value_count = require(functions.get_table_value_count)
local experimental_physical_backpack = require(client.experimental_physical_backpack)

local Iris = require(root.Iris).Init()

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

local system_version = package and `v0.0.{package.VersionNumber}` or "Unknown Version"
Iris:Connect(function()
	if module.visible then
		local character = characters.get_local_character()
		local is_backpack_open = experimental_physical_backpack.is_open
		Iris.Window({`HAKUREALITY Debugger — {system_version}` :: any, nil, nil, nil, true})
			Iris.Text({`FPS: {render_counter.value}`})
			Iris.Text({`Characters: {get_table_value_count(characters.items)}`})
			if character then
				Iris.Tree({"Local Character"})
					Iris.Text({`model: {character.model:GetFullName()}`})
					Iris.Text({`is_dead: {character.is_dead}`})
					Iris.Text({`humanoid: {character.humanoid and character.humanoid:GetFullName()}`})
					Iris.Text({`left_foot: {character.left_foot and character.left_foot:GetFullName()}`})
					Iris.Text({`right_foot: {character.right_foot and character.right_foot:GetFullName()}`})
					Iris.Text({`waist_motor: {character.waist_motor and character.waist_motor:GetFullName()}`})
					Iris.Text({`connections: {#character.connections}`})
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
				Iris.End()
			end
			Iris.Tree({"Physical Backpack"})
				Iris.Text({`open: {is_backpack_open}`})
				if is_backpack_open then
					local gui = assert(experimental_physical_backpack.current_gui)
					Iris.Text({`items: {#gui.items}`})
					Iris.Text({`position: {gui.position}`})
					Iris.Text({`current_item: {gui.current_item}`})
				end
			Iris.End()
		Iris.End()
	end
end)

return module