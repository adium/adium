global HandyAdiumScripts

on run
	tell application "Adium"
		set n to (get name of window 1)
		try
			set name of window 1 to "dummy"
			--I shouldn't get here
			set name of window 1 to n --restore
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run