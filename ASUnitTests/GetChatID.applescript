global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		set n to (HandyAdiumScripts's defaultService & "." & HandyAdiumScripts's defaultParticipant)
		if (get id of newChat) is not n then
			close newChat --restore
			error
		end
		close newChat --restore
	end tell
end run