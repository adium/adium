global HandyAdiumScripts

on run
	tell application "Adium"
		set c to count accounts
		tell service "AIM"
			set newAccount to make new account with properties {name:"test"}
		end tell
		if (count accounts) is not c + 1 then
			--for some reason, I failed to make an account.
			--no cleanup is necessary
			error
		end
		delete newAccount
	end tell
end run