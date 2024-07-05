--!strict
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")

local functions = script.Parent.Parent.functions
local item_button = script.item_button
local local_player = assert(Players.LocalPlayer)
local local_player_gui = local_player.PlayerGui
local name_bubble = script.name_bubble
local selection_interface = script.selection_interface
local vr_enabled = VRService.VREnabled

local create_static_viewport_of_model = require(functions.create_static_viewport_of_model)
local get_camera = require(functions.get_camera)
local get_point_on_plane = require(functions.get_point_on_plane)

local backpack_gui: {
	cursor: ImageLabel,
	cursor_inner: ImageLabel,
	
	gui: SurfaceGui,
	part: Part,
	items: {{
		button: ImageLabel & {
			border: Frame
		},
		button_image: ImageLabel | ViewportFrame,
		button_stroke: UIStroke,
		
		instance: Tool,
		hover_alpha: number,
		hover_interface: {
			gui: SurfaceGui,
			instance: Part
		}?
	}},
	
	name_bubble: ImageLabel & {
		text: TextLabel,
		scale: UIScale
	},
	name_bubble_alpha: number,
	
	position: Vector3,
	current_item: number?,
	hover_alpha: number,
	last_hover_item: number?
}?

local module = {
	current_gui = backpack_gui,
	is_open = false
}

function create_item_hover_interface()
	local interface_part = selection_interface:Clone()
	interface_part.SurfaceGui.cursor:Destroy()
	
	return interface_part
end

local open_tween_info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
function module.open()
	if backpack_gui then
		module.close()
	end
	module.is_open = true
	
	local character = local_player.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end

	local interface_part = selection_interface:Clone()
	local interface = interface_part.SurfaceGui

	local items = {}
	local backpack = local_player:FindFirstChildWhichIsA("Backpack")
	if backpack then
		for _,child in backpack:GetChildren() do
			if child:IsA("Tool") then
				local button = item_button:Clone()
				local image_asset = child.TextureId
				local button_image = button.item_image
				if #image_asset > 0 then
					button_image.Image = image_asset
				else
					button_image:Destroy()
					button_image = create_static_viewport_of_model(child, button_image.Size)
					button_image.Position = UDim2.fromScale(0.5, 0.5)
					button_image.AnchorPoint = Vector2.one / 2
					button_image.ImageTransparency = 1
					button_image.Parent = button
				end

				TweenService:Create(button, open_tween_info, { ImageTransparency = 0.5 }):Play()
				TweenService:Create(button_image, open_tween_info, { ImageTransparency = 0 }):Play()
				TweenService:Create(button.UIScale, open_tween_info, { Scale = 1 }):Play()
				TweenService:Create(button.border.UIStroke, open_tween_info, { Transparency = 0.5 }):Play()
				table.insert(items, {
					button = button,
					button_image = button_image,
					button_stroke = button.border.UIStroke,
					
					instance = child,
					hover_alpha = 0
				})
			end
		end
	end
	
	-- TODO: improve positioning, needs more complicated math instead of a lazy loop
	local count = #items

	local done = 0
	local depth = 1
	local amount = 7
	local remaining = count
	repeat
		local count = math.min(amount, remaining)
		for index = 1, count do
			local item = items[done + index]
			local button = item.button
			local angle = index * 2 * math.pi / count
			local distance = 80 + 80 * (depth - 1)
			button.Position = UDim2.new(0.5, math.sin(angle) * distance, 0.5, math.cos(angle) * distance)
			button.Parent = interface
		end
		done += count
		depth += 1
		amount += 6
		remaining -= count
	until remaining <= 0

	interface_part.Parent = get_camera()
	
	interface.Adornee = interface_part
	interface.Parent = local_player_gui

	local name_bubble = name_bubble:Clone()
	backpack_gui = {
		gui = interface,
		part = interface_part,
		items = items,
		cursor = interface.cursor,
		cursor_inner = interface.cursor.ImageLabel,
		
		name_bubble = name_bubble,
		name_bubble_alpha = 0,
		
		position = vr_enabled and VRService:GetUserCFrame(Enum.UserCFrame.RightHand).Position or -Vector3.zAxis * 0.05,
		hover_alpha = 0
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
					humanoid:EquipTool(item.instance)
				end
			end
		end
		
		for _,item in backpack_gui.items do
			local hover_interface = item.hover_interface
			if hover_interface then
				hover_interface.gui:Destroy()
				hover_interface.instance:Destroy()
			end
		end

		backpack_gui.gui:Destroy()
		backpack_gui.part:Destroy()
		backpack_gui, module.current_gui = nil
	end
end

-- TODO: refactor entire function
function module.render(delta_time: number)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	
	if backpack_gui then
		-- position layer 1 of the backpack interface
		local camera_cframe = get_camera().CFrame
		local interface_position = camera_cframe * (backpack_gui.position * 2)
		local interface_cframe = CFrame.lookAt(interface_position, camera_cframe.Position)
		backpack_gui.part.CFrame = interface_cframe

		-- calculate the position of the cursor
		local plane_point = get_point_on_plane(backpack_gui.part.CFrame, (camera_cframe * VRService:GetUserCFrame(Enum.UserCFrame.RightHand)).Position)
		local plane_point_relative = -backpack_gui.part.CFrame:PointToObjectSpace(plane_point) + Vector3.new(2, 2, 0)

		local cursor_vector = (Vector2.new(plane_point_relative.X, plane_point_relative.Y) / 4) * 1024
		local cursor_position = UDim2.fromOffset(cursor_vector.X, cursor_vector.Y)
		local cx, cy = cursor_vector.X, cursor_vector.Y

		-- figure out which item is being hovered over
		local current_item, current_item_index
		for index, item in backpack_gui.items do
			local button = item.button
			local start = button.AbsolutePosition
			local stop = start + button.AbsoluteSize
			if cx >= start.X and cy >= start.Y and cx <= stop.X and cy <= stop.Y then
				current_item, current_item_index = item, index
				break
			end
		end
		
		-- fun animations
		local hover_alpha = backpack_gui.hover_alpha
		local hover_alpha_target = current_item and 1 or 0
		if hover_alpha < hover_alpha_target then
			hover_alpha = math.min(hover_alpha + delta_time * 4, hover_alpha_target)
		elseif hover_alpha > hover_alpha_target then
			hover_alpha = math.max(hover_alpha - delta_time * 4, hover_alpha_target)
		end
		
		backpack_gui.hover_alpha = hover_alpha
		if backpack_gui.hover_alpha == 0 then
			backpack_gui.last_hover_item = nil
		end
		
		for _,item in backpack_gui.items do
			local hover_alpha = item.hover_alpha
			local hover_alpha_target = item == current_item :: any and 1 or 0
			if hover_alpha < hover_alpha_target then
				hover_alpha = math.min(hover_alpha + delta_time * 4, hover_alpha_target)
			elseif hover_alpha > hover_alpha_target then
				hover_alpha = math.max(hover_alpha - delta_time * 4, hover_alpha_target)
			end
			
			item.hover_alpha = hover_alpha
			if hover_alpha > 0 then
				if not item.hover_interface then
					local interface = create_item_hover_interface()
					local surface_gui = interface.SurfaceGui
					
					local button_image = item.button_image :: GuiObject
					button_image.Position = item.button.Position
					button_image.Parent = surface_gui
					
					interface.Parent = get_camera()
					
					surface_gui.Adornee = interface
					surface_gui.Parent = local_player_gui
					
					item.hover_interface = {
						gui = surface_gui,
						instance = interface
					}
				end
				
				local interface = assert(item.hover_interface)
				
				local size = 48 + (8 * hover_alpha)
				;(item.button_image :: any).Size = UDim2.fromOffset(size, size)
				interface.instance.CFrame = interface_cframe * CFrame.new(0, 0, -hover_alpha / 8)
			else
				local button_image = item.button_image :: GuiObject
				button_image.Position = UDim2.fromScale(0.5, 0.5)
				button_image.Parent = item.button
				
				local hover_interface = item.hover_interface
				if hover_interface then
					hover_interface.gui:Destroy()
					hover_interface.instance:Destroy()
					
					item.hover_interface = nil
				end
			end
			
			item.button_stroke.Color = Color3.new(0, 0, 0):Lerp(Color3.new(1, 1, 1), hover_alpha)
			item.button_stroke.Transparency = 0.5 * (1 - hover_alpha)
		end
		
		-- animate item name bubble
		if current_item then
			local alpha = backpack_gui.name_bubble_alpha
			if alpha < 1 then
				alpha += delta_time * 10
				backpack_gui.name_bubble_alpha = alpha
			end
			
			local name_bubble = backpack_gui.name_bubble
			name_bubble.text.Text = current_item.instance.Name
			name_bubble.scale.Scale = alpha ^ 0.5
			name_bubble.Position = current_item.button.Position + UDim2.fromOffset(0, -40)
			name_bubble.Parent = backpack_gui.gui
		else
			backpack_gui.name_bubble.Parent = nil
			backpack_gui.name_bubble_alpha = 0
		end
		
		-- set cursor position & animate
		local cursor = backpack_gui.cursor
		
		local size1 = 24 + (40 * hover_alpha)
		cursor.Size = UDim2.fromOffset(size1, size1)
		cursor.ImageTransparency = hover_alpha
		
		local size2 = 16 + (48 * hover_alpha)
		backpack_gui.cursor_inner.Size = UDim2.fromOffset(size2, size2)
		
		local item = current_item or backpack_gui.items[backpack_gui.last_hover_item :: number]
		if item then
			backpack_gui.cursor.Position = cursor_position:Lerp(item.button.Position, hover_alpha)
		else
			backpack_gui.cursor.Position = cursor_position
		end

		-- set item variables
		backpack_gui.current_item = current_item_index
		if current_item_index then
			backpack_gui.last_hover_item = current_item_index
		end
	end
end

return module