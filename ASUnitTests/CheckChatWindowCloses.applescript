global HandyAdiumScripts

on run
	tell application "Adium"
		set newChatWindow to HandyAdiumScripts's makeNewChatWindow()
		set c to count of chat windows
		close newChatWindow
		delay 1
		if (count of chat windows) is not c - 1 then error ("Count of chat windows is " & (count of chat windows) & " when it should be " & (c - 1))
	end tell
end run