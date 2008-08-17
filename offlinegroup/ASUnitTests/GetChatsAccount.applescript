global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		if (get account of newChat) is not account (HandyAdiumScripts's defaultAccount) then
			-- this tests both account's objectSpecifier and chat's account
			-- method
			close newChat --restore
			error
		end
		close newChat --restore
	end tell
end run