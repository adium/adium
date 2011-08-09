on title()
	return "Adium Version"
end title

on keyword()
	return "%_adiumversion"
end keyword

on substitute()
	return "<HTML><A HREF=\"http://www.adiumx.com\">Adium " & (version of application "Adium") & "</A></HTML>"
end substitute
return "<HTML><A HREF=\"http://www.adiumx.com\">Adium " & (version of application "Adium") & "</A></HTML>"
