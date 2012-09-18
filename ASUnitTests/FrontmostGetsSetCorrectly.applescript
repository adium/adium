global HandyAdiumScripts

on run
	tell application "Adium"
		activate
		if not (get frontmost) then error --more of an error with Apple's stuff, but hey, I can still check for it.
	end tell
end run