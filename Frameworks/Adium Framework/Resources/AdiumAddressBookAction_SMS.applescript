on cleanString(str, chars)
	set tid to AppleScript's text item delimiters
	repeat with c in chars
		set AppleScript's text item delimiters to {c}
		set chunks to text items of str
		set AppleScript's text item delimiters to ""
		set str to chunks as Unicode text
	end repeat
	set AppleScript's text item delimiters to tid
	return str
end cleanString

using terms from application "Address Book"
	on action property
		return "phone"
	end action property
	
	on action title for aPerson with phoneNumber
		return ("Adium: Send message to " & (value of phoneNumber as string))
	end action title
	
	on should enable action for aPerson with phoneNumber
		return true
	end should enable action
	
	on perform action for aPerson with phoneNumber
		(* remove ignored phone characters *)
		set phoneNumber to my cleanString(value of phoneNumber as string, {" ", "-", ")", "(", "."})
		
		if (phoneNumber does not start with "1") and (phoneNumber does not start with "+") then
			(* If the phone number neither starts with "1" nor with "+", add "+1" to it *)
			set phoneNumber to "+1" & phoneNumber
		else if (phoneNumber does not start with "+") then
			(* If the phone number does not start with "+", add "+" to it *)
			set phoneNumber to "+" & phoneNumber
		end if
		
		using terms from application "Adium"
			tell application "Adium"
				(* We want a AIM account to be online or connecting before proceeding *)
				if ((accounts of service "AIM" whose status type is not offline) = 0) then
					tell (the first account of service "AIM") to go online
					(* Ideally, this activate will not return until Adium is ready to make a new chat window. Just to be sure, we'll busy wait. *)
					repeat while ((accounts of service "AIM" whose status type is not offline) = 0)
						activate
					end repeat
				end if
				(* Create the chat and find the contact it is with *)
				tell (first account of service "AIM" whose status type is not offline)
					set myContact to make new contact with properties {name:phoneNumber}
					make new chat with contacts {myContact} with new chat window
				end tell
				activate
			end tell
		end using terms from
		
		return true
	end perform action
	
end using terms from