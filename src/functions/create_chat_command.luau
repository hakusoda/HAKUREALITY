--!strict
local TextChatService = game:GetService("TextChatService")

local can_create = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
return function(primary_alias: string, callback: (origin_text_source: TextSource, unfiltered_text: string) -> ()?): TextChatCommand?
	if can_create then
		local command = Instance.new("TextChatCommand")
		command.Name = `HAKUREALITY{primary_alias}`
		command.PrimaryAlias = primary_alias
		
		if callback then
			command.Triggered:Connect(callback)
		end
	
		command.Parent = TextChatService
		
		warn(`[HAKUREALITY]: created chat command "{primary_alias}"`)
		return command
	end
	
	return nil
end