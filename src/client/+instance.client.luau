--!strict
local root = script.Parent
local functions = root.functions
local server_debug_events = root.server_debug_events

local constants = require(root.constants)
local debug_gui = require(script.debug_gui)
local show_notification = require(functions.show_notification)
local attach_chat_command_callback = require(functions.attach_chat_command_callback)

local package = constants.PACKAGE
require(script.local_handler)
require(script.player_handler)

attach_chat_command_callback("/hakudebug", function()
	debug_gui.visible = not debug_gui.visible
	if math.random(1, 1000) == 1 then
		show_notification("<(0_0<) <(0_0)> (>0_0)> KIRBY DANCE")
	end
end)
attach_chat_command_callback("/hakudebugserver", function()
	show_notification("sending debug session request to the server...")
	server_debug_events:FireServer(0)
end)

server_debug_events.OnClientEvent:Connect(function(event: number)
	if event == 0 then
		show_notification("you lack permission... (*_ _)人")
	end
end)

warn(`[HAKUREALITY]: fully initialised, yummy! currently on version {constants.VERSION} (r{constants.PACKAGE_VERSION}), was loaded from {root:GetAttribute("was_imported_via_loader") and "the require-based loader" or package and package.PackageId == "rbxassetid://15429676683" and "HAKUMI's public package" or "a third-party package, not maintained by HAKUMI" or "an unknown source, not maintained by HAKUMI"}.`)
warn("[HAKUREALITY]: hello, console dweller, if you witness any \"flaws\" with players in virtual reality, pretty please report it directly to HAKUMI!")