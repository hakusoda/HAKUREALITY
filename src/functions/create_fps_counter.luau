--!strict
export type FpsCounter = {
	value: number,
	active: boolean
}
return function(callback: RBXScriptSignal): FpsCounter
	local object: FpsCounter = {
		value = 0,
		active = true
	}
	
	local frame_count = 0
	local stop_counting_at = os.clock() + 1
	callback:Connect(function()
		if object.active then
			local current_time = os.clock()
			if current_time >= stop_counting_at then
				object.value = frame_count
				frame_count = 0
				stop_counting_at = current_time + 1
			end
			frame_count += 1
		end
	end)
	
	return object
end