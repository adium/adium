global HandyAdiumScripts

on run
	tell application "Adium"
		set c to (get visible of window 1)
		set visible of window 1 to not c
		if (get visible of window 1) is c then
			--visibility change failed; nothing to revert
			error
		end
		set visible of window 1 to c
	end tell
end run