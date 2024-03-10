--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local local_player = assert(Players.LocalPlayer)
local local_player_gui = local_player.PlayerGui
local notification_gui = script.notification_gui

local active = false
local waiting_threads: { thread } = {}
return function(text: string)
	task.defer(function()
		if active then
			local thread = coroutine.running()
			table.insert(waiting_threads, thread)
			
			coroutine.yield()
		end
		active = true
		
		local new_gui = notification_gui:Clone()
		new_gui.label.Text = text
		new_gui.Parent = local_player_gui
		
		Debris:AddItem(new_gui, 5)
		
		task.delay(5, function()
			local next_thread = waiting_threads[1]
			if next_thread then
				table.remove(waiting_threads, 1)
				task.defer(next_thread)
			else
				active = false
			end
		end)
	end)
end