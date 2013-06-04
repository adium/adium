global HandyAdiumScripts

on run
	tell application "Adium"
		set newChatWindow to HandyAdiumScripts's makeNewChatWindow()
		if (get index of chat 1 of newChatWindow) is not 1 then
			close newChatWindow --restore
			error
		end
		close newChatWindow --restore
	end tell
end run