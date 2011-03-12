global HandyAdiumScripts

on run
	tell application "Adium"
		set n to (get name)
		try
			set name to "dummy"
			--never get here
			set name to n --reset
			error
		on error number num --trap all errors
			if num is -2700 then error -- if the error is the default error, caused by the 'error' directive, pass it along the chain
			--otherwise, the command threw correctly
		end try
	end tell
end run