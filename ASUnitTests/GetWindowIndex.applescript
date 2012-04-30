global HandyAdiumScripts

on run
	tell application "Adium"
		if (get index of window 1) is not 1 then
			--this is also indicative of a much larger problem
			--check the sdef for an error with window's 'pidx' property
			error
		end
	end tell
end run