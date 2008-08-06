global HandyAdiumScripts

on run
	tell application "Adium"
		set newAccount to HandyAdiumScripts's makeTemporaryAccount()
		set c to count accounts
		delete newAccount
		if (count accounts) is not c - 1 then
			--it's possible that something bad happened
			--because I couldn't delete the account I created
			--however, there's nothing I can do about it. I'll
			--print a message to the user, though.
			do script "echo 'It is possible that an extra temporary account has been created by running this unit test. Please delete the account " & (get the name of newAccount) & " and fix the account creation or deletion code."
			error
		end
	end tell
end run