global HandyAdiumScripts

on run
	tell application "Adium"
		set c to (get closeable of window 1)
		try
			set closeable of window 1 to (not c)
			--should not get here
			set closeable of window 1 to c --restore
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run