global HandyAdiumScripts

on run
	tell application "Adium"
		if (get name of service "AIM") is not "AIM" then error
	end tell
end run