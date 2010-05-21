global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		try
			set id of newChat to "dummy"
			error
		on error number num
			if num = -2700 then error
		end try
		close newChat
	end tell
end run