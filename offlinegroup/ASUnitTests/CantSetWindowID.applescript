global HandyAdiumScripts

on run
	tell application "Adium"
		try
			set id of window 1 to 4983
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run