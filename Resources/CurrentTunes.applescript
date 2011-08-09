try
	tell application "System Events"
		set iTunes to ((application processes whose (name is equal to "iTunes")) count)
	end tell
	
	if iTunes is greater than 0 then
		with timeout of 3 seconds
			using terms from application "iTunes"
				tell application "iTunes"
					if player state is not stopped then
						set seperator to ",$!$,"
						set songname to name of current track
						set songartist to artist of current track
						set songalbum to album of current track
						set songyear to year of current track
						set songurl to ""
						
						if player state is paused then
							set playerstate to "Paused"
						else
							set playerstate to "Playing"
						end if
						
						set info to (songalbum & seperator) & (songartist & seperator) & (composer of current track & seperator) & (genre of current track & seperator) & (playerstate & seperator) & (songname & seperator) & ((songyear as string) & seperator) & songurl as string
						return info
					end if
				end tell
			end using terms from
		end timeout
	end if
	return "None"
end try