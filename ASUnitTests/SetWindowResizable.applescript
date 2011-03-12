global HandyAdiumScripts

on run
	tell application "Adium"
		set r to (get resizable of window 1) --for later restoration
		try
			set resizable of window 1 to (not r)
			--should not get here
			set resizable of window 1 to r
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run