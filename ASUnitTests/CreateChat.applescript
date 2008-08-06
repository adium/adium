global HandyAdiumScripts

on run
	tell application "Adium"
		set c to count chat windows
		set c2 to count chats
		tell account (HandyAdiumScripts's defaultAccount)
			set newChat to make new chat with contacts {contact (HandyAdiumScripts's defaultParticipant)} with new chat window
			set newChatWindow to (get window of newChat)
			if (count chat windows of application "Adium") is not c + 1 then
				close newChatWindow --restore
				error
			end
			if (count chats of application "Adium") is not c2 + 1 then
				close newChatWindow --restore
				error
			end
			if (count chats of newChatWindow) is not 1 then
				close newChatWindow --restore
				error
			end
			set newChat2 to make new chat with contacts {contact (HandyAdiumScripts's otherParticipant)} at end of chats of newChatWindow
			if (count chat windows of application "Adium") is not c + 1 then
				close newChatWindow
				error
			end
			if (count chats of application "Adium") is not c2 + 2 then
				close newChatWindow
				error
			end
			if (count chats of newChatWindow) is not 2 then
				close newChatWindow
				error
			end
			close newChatWindow
		end tell
	end tell
end run