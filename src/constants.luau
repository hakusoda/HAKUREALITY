--!strict
local package_link = script.Parent:FindFirstChildWhichIsA("PackageLink")
return table.freeze({
	COMFORT_RATINGS = table.freeze({
		[-1] = "Unrated",
		[0] = "Comfortable",
		[1] = "Moderate",
		[2] = "Intense"
	}),
	DISABLE_IK_ATTRIBUTE = "disableInverseKinematics",
	
	PACKAGE = package_link,
	PACKAGE_VERSION = package_link and package_link.VersionNumber,
	
	SETUP_ATTRIBUTE = "HAKUREALITY_SETUP",
	
	VERSION = "0.1.2",
})