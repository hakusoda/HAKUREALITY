--!strict
local root = script.Parent
local package = root:FindFirstChildWhichIsA("PackageLink")

local strict_default = require(root.functions.strict_default)
return table.freeze({
	VERSION = "0.1.0",
	
	PACKAGE = package,
	PACKAGE_VERSION = package and package.VersionNumber,
	
	SETUP_ATTRIBUTE = "HAKUREALITY_SETUP",
	DISABLE_IK_ATTRIBUTE = "disableInverseKinematics",
	
	COMFORT_RATING = strict_default(root:GetAttribute("comfort_rating"), -1),
	REPLICATION_RATE = strict_default(root:GetAttribute("replication_rate"), 20),
	SHOW_PHOTOSENSITIVITY_WARNING = strict_default(root:GetAttribute("show_photosensitivity_warning"), false)
})