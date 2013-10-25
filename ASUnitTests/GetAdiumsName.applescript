global HandyAdiumScripts

on run
	tell application "Adium"
		if (get name) is not "Adium" then error
	end tell
end run