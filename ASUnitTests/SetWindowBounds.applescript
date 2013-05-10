global HandyAdiumScripts

on run
	tell application "Adium"
		set b to (get bounds of window 1) -- for later restoration
		set bounds of window 1 to {0, 0, 40, 40}
		if (get bounds of window 1) is not {0, 0, 40, 40} then
			--It's possible that by calling set, I've done some kind of
			--undefined behavior, so that I can't reliably call it again
			--to restore the window bounds
			--However, it's more likely that the setBounds method is simply
			--not implemented, so no harm was done. No need to restore, then.
			error
		end
		--however, if I'm here, then I do need to restore
		set the bounds of window 1 to b
	end tell
end run