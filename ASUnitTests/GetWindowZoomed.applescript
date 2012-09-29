global HandyAdiumScripts

on run
	tell application "Adium"
		set c to (get zoomed of window 1)
		set zoomed of window 1 to not c
		delay 2 --give the command time to finish, as it doesn't block.
		if (get zoomed of window 1) is c then
			--the change didn't work, so no reverting is necessary
			error
		end
		set zoomed of window 1 to c
		delay 2
	end tell
end run