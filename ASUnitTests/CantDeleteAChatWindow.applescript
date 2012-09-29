global HandyAdiumScripts

on run
	tell application "Adium"
		set newChatWindow to HandyAdiumScripts's makeNewChatWindow()
		try
			delete newChatWindow
			error
		on error number num --trap all errors
			if num is -2700 then error -- if the error is the default error, caused by the 'error' directive, pass it along the chain
			--otherwise, the command threw correctly
		end try
		close newChatWindow
	end tell
end run