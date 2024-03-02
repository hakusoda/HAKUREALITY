--!strict
local TextChatService = game:GetService("TextChatService")

local can_create = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
return function(primary_alias: string, callback: (origin_text_source: TextSource, unfiltered_text: string) -> ()): TextChatCommand?
	if can_create then
		local command = Instance.new("TextChatCommand")
		command.PrimaryAlias = primary_alias
		command.Triggered:Connect(callback)
		command.Parent = TextChatService
		
		return command
	end
	
	return nil
end