global HandyAdiumScripts

on run
	tell application "Adium"
		if not (exists service "AIM") then error
	end tell
end run