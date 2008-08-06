global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		tell account (HandyAdiumScripts's defaultAccount)
			set newChat2 to make new chat with contacts {contact (HandyAdiumScripts's otherParticipant)} at end of chats of (get window of newChat)
		end tell
		set c to count chats of (get window of newChat)
		close newChat2
		if (count chats of (get window of newChat)) is not c - 1 then error
		close (get window of newChat)
	end tell
end run