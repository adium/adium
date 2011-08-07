on substitute()
	return do shell script "awk -F\" [|] \" '{print $1}' " & (POSIX path of (path to application "Adium" as string)) & "Contents/Resources/buildnum" & "| grep \"[a-z0-9]\""
end substitute
