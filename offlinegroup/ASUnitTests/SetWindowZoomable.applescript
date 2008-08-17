global HandyAdiumScripts

on run
	tell application "Adium"
		set z to (get zoomable of window 1) --for later restoration
		try
			set zoomable of window 1 to (not z)
			--I shouldn't ever get here.
			--If I have, I know I've screwed something up, and should revert it.
			set zoomable of window 1 to z
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run