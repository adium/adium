global HandyAdiumScripts

on run
	tell application "Adium"
		set m to (get minimizable of window 1)
		try
			set minimizable of window 1 to false
			--should never get here
			set minimizable of window 1 to m --restore
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run