global HandyAdiumScripts

on run
	tell application "Adium"
		activate
	end tell
	tell application "System Events"
		if not (exists application process "Adium") then error
	end tell
end run