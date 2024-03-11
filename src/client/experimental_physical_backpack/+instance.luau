--!strict
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")

local functions = script.Parent.Parent.functions
local local_player = Players.LocalPlayer

local get_camera = require(functions.get_camera)
local get_point_on_plane = require(functions.get_point_on_plane)

local backpack_gui: {
	part: Part,
	test: Frame,
	items: {{
		ui: TextButton,
		tool: Tool
	}},
	position: Vector3,
	current_item: number?
}?

local module = {
	is_open = false,
	current_gui = backpack_gui
}

function module.open()
	module.is_open = true
	if backpack_gui then
		module.close()
	end
	
	local character = local_player.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end

	local part = script.toolGui:Clone()

	local items = {}
	local backpack = local_player:FindFirstChildWhichIsA("Backpack")
	if backpack then
		for _,child in backpack:GetChildren() do
			if child:IsA("Tool") then
				local button = Instance.new("TextButton")
				button.Size = UDim2.fromOffset(56, 56)
				button.FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Medium)
				button.TextColor3 = Color3.new(1, 1, 1)
				button.AnchorPoint = Vector2.one / 2
				button.BackgroundColor3 = Color3.new(0, 0, 0)
				button.BackgroundTransparency = 0.5

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.5, 0)
				corner.Parent = button

				local icon = child.TextureId
				if icon and #icon > 0 then
					local image = Instance.new("ImageLabel")
					image.Size = UDim2.fromScale(1, 1)
					image.Image = child.TextureId
					image.BackgroundTransparency = 1
					image.Parent = button

					button.Text = ""
				else
					button.Text = child.Name
				end

				table.insert(items, {
					ui = button,
					tool = child
				})
			end
		end
	end
	
	-- TODO: improve positioning, needs more complicated math instead of a lazy loop
	local count = #items

	local done = 0
	local depth = 1
	local amount = 8
	local remaining = count
	repeat
		local count = math.min(amount, remaining)
		for index = 1, count do
			local item = items[done + index]
			local ui = item.ui
			local angle = index * 2 * math.pi / count
			local distance = 80 + 64 * (depth - 1)
			ui.Position = UDim2.new(0.5, math.sin(angle) * distance, 0.5, math.cos(angle) * distance)
			ui.Parent = part.SurfaceGui
		end
		done += count
		depth += 1
		amount += 6
		remaining -= count
	until remaining <= 0

	local test = Instance.new("Frame")
	test.Size = UDim2.fromOffset(8, 8)
	test.AnchorPoint = Vector2.one / 2
	test.BorderSizePixel = 0
	test.BackgroundColor3 = Color3.new(1, 0, 0)
	test.Parent = part.SurfaceGui

	part.Parent = get_camera()

	backpack_gui = {
		part = part,
		test = test,
		items = items,
		position = VRService:GetUserCFrame(Enum.UserCFrame.RightHand).Position or -Vector3.zAxis * 4
	}
	module.current_gui = backpack_gui
end

function module.close()
	module.is_open = false
	if backpack_gui then
		local item = backpack_gui.items[backpack_gui.current_item :: number]
		if item then
			local character = local_player.Character
			if character then
				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid:EquipTool(item.tool)
				end
			end
		end

		backpack_gui.part:Destroy()
		backpack_gui, module.current_gui = nil
	end
end

-- TODO: refactor entire function
function module.render()
	if backpack_gui then
		local cc = get_camera().CFrame
		local pos = cc * backpack_gui.position
		backpack_gui.part.CFrame = CFrame.lookAt(pos, cc.Position) * CFrame.new(0, 0, 2)

		local point = get_point_on_plane(backpack_gui.part.CFrame, (cc * VRService:GetUserCFrame(Enum.UserCFrame.RightHand)).Position)
		local relative = -backpack_gui.part.CFrame:PointToObjectSpace(point)
		relative += Vector3.new(2, 2, 0)

		local po = Vector2.new(relative.X / 4, relative.Y / 4) * 1024
		local alpha = UDim2.fromOffset(po.X, po.Y)
		backpack_gui.test.Position = alpha

		local currentItem = nil
		for index, item in backpack_gui.items do
			local start = item.ui.AbsolutePosition
			local stop = start + item.ui.AbsoluteSize
			if po.X >= start.X and po.Y >= start.Y and po.X <= stop.X and po.Y <= stop.Y then
				currentItem = index
				break
			end
		end

		backpack_gui.current_item = currentItem
	end
end

return module