global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChatWindow()
		set cw to (count chat windows)
		close newChat
		delay 1
		if (count chat windows) is not cw - 1 then
			--ooh! A helpful message.
			--trying to close again isn't going to help... So I won't restore.
			error ("count chat windows is " & (count chat windows) & " rather than " & (cw - 1))
		end
		if (exists newChat) then
			--testing that closing makes something not exist
			--Again, if this fails, not much I can do to restore.
			error
		end
	end tell
end run