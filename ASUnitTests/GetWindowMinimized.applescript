global HandyAdiumScripts

on run
	tell application "Adium"
		set c to minimized of window 1 --for later restore
		set minimized of window 1 to (not c)
		if (get minimized of window 1) is c then
			--nothing to restore
			error
		end
		set minimized of window 1 to c --restore
	end tell
end run