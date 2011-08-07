--Active app shows the current app.
on substitute()
	tell application "System Events"
		set appName to name of item 1 of (application processes whose frontmost is true)
		if appName is "ScreenSaverEngine" then
			set appName to "(#)" & "Screen Saver"
		end if
		return appName
	end tell
end substitute