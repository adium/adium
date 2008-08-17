global HandyAdiumScripts

on run
	tell application "Adium"
		set n to (get name of service "AIM")
		set s to (get service "AIM")
		try
			set name of service "AIM" to "dummy"
			--should never get here!
			set name of s to n --restore
			--actually this won't restore because service names are what's 
			--used in objectSpecifier to refer to these objects...
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run