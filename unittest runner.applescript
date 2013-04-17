(* Read Me.

This is the unit test runner for AppleScript. In order to run them from the command line, in adium/ folder, use
osascript unittest\ runner.applescript 
piped to 
 tr '\r' '\n'

For some reason, Script Editor doesn't like the pipe character...

Anyway, this will compile and run the AppleScripts in ASUnitTests and report the results. The tr translates the old Mac CR to Unix LF. You should see Adium leap about while this is happening. Every unit test should clean up after itself, so that no windows are left lying around, extra accounts existing, etc.

The runner will report if any tests failed and the error number and message. It will also summarize with a number succeeded out of the total number.
*)

property unitTestDir : "ASUnitTests/"

script HandyAdiumScripts
	property defaultService : "AIM"
	property defaultAccount : "applmak"
	property defaultParticipant : "applmak"
	property otherParticipant : "boredzo"
	on makeTemporaryAccount()
		tell application "Adium"
			tell service defaultService
				return make new account with properties {title:"test"}
			end tell
		end tell
	end makeTemporaryAccount
	on makeNewChatWindow()
		tell application "Adium"
			set newChat to my makeNewChat()
			return (get window of newChat)
		end tell
	end makeNewChatWindow
	on makeNewChat()
		tell application "Adium"
			tell account defaultAccount
				set newChat to make new chat with contacts {my findSomeParticipant()} with new chat window
			end tell
			return newChat
		end tell
	end makeNewChat
	on findSomeParticipant()
		tell application "Adium"
			tell account defaultAccount
				if exists contact defaultParticipant then
					return contact defaultParticipant
				else
					if (count contacts) > 1 then
						return some contact
					else
						-- we're offline?
						error "Can't get any contacts because account is offline."
						return missing value
					end if
				end if
			end tell
		end tell
	end findSomeParticipant
	on cleanup()
		tell application "Adium"
			repeat while exists chat window 1
				close chat window 1
			end repeat
		end tell
	end cleanup
end script

on run
	--compile the .applescript files
	do shell script "for i in " & quoted form of unitTestDir & "*.applescript; do s=`basename $i .applescript`; osacompile -o " & quoted form of unitTestDir & "/${s}.scpt " & quoted form of unitTestDir & "/${s}.applescript ; done;"
	--get contents of unitTestDir
	tell application "Finder"
		set unittestScripts to every file of folder ((POSIX file unitTestDir) as text) whose name extension is "scpt"
		set report to ""
		set successReport to ""
		set total to 0
		set failed to 0
		set startTime to current date
		repeat with s in unittestScripts
			set nameOfS to (get name of s)
			--do any set up or takedown
			--For speed concerns, I'm going to assume that a unit test will do these
			try
				set unittest to load script file ((((POSIX file unitTestDir) as text) & nameOfS))
				try
					set total to total + 1
					tell unittest to run
					set successReport to successReport & nameOfS & ": Success!" & return
				on error msg number num
					set failed to failed + 1
					if num is -2700 then
						--assertion failed!
						set report to report & nameOfS & ": " & "Assertion Failed: " & num & ": " & msg & return
					else
						--some exception
						set report to report & nameOfS & ": " & "Unexpected Exception: " & num & ": " & msg & return
					end if
				end try
			on error
				set report to report & nameOfS & ": " & "Error Loading Script!" & return
			end try
		end repeat
	end tell
	set report to "Number Of Successes/Total: " & (total - failed) & "/" & total & return & "Time: " & ((current date) - startTime) & "s" & return & report & "-----" & return & successReport
	report
end run