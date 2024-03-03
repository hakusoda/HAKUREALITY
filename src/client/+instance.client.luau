--!strict
local root = script.Parent
local functions = root.functions

local constants = require(root.constants)
local debug_gui = require(script.debug_gui)
local local_handler = require(script.local_handler)
local player_handler = require(script.player_handler)
local create_chat_command = require(functions.create_chat_command)

local package = constants.PACKAGE
local system_version = constants.VERSION
create_chat_command("/hakudebug", function()
	debug_gui.visible = not debug_gui.visible
end)

warn(`[HAKUREALITY]: fully initialised, yummy! currently on version {system_version or "😓❓"}, was loaded from {root:GetAttribute("was_imported_via_loader") and "the require-based loader" or package and package.PackageId == "rbxassetid://15429676683" and "HAKUMI's public package" or "a third-party package, not maintained by HAKUMI" or "an unknown source, not maintained by HAKUMI"}.`)
warn("[HAKUREALITY]: hello, console dweller, if you witness any \"flaws\" with players in virtual reality, pretty please report it directly to HAKUMI!")