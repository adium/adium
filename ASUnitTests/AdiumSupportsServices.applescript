global HandyAdiumScripts

on run
	tell application "Adium"
		if (count services) is 0 then error
	end tell
end run