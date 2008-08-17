global HandyAdiumScripts

on run
	tell application "Adium"
		if (get name of window "Contacts") is not "Contacts" then
			--this is actually indicative of complicated AS problem
			--It will most likely involve changing the sdef so that
			--the windows's pnam is set correctly
			error
		end
	end tell
end run