--!strict
local TextChatService = game:GetService("TextChatService")

local can_attach = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
return function(primary_alias: string, callback: (origin_text_source: TextSource, unfiltered_text: string) -> ())
	if can_attach then
		task.defer(function()
			local command = TextChatService:WaitForChild(`HAKUREALITY{primary_alias}`)
			command.Triggered:Connect(callback)
			
			warn(`[HAKUREALITY]: attached callback {string.sub(tostring(callback), 11)} to chat command "{primary_alias}"`)
		end)
	end
end