-- There are different patterns used by 'uptime':

-- uptime < 60 secs
-- e.g. '19:04  up 41 secs, 2 users, load averages: 2.17 0.59 0.22'

-- uptime < 60 mins
-- e.g. '19:09  up 6 mins, 2 users, load averages: 0.65 1.23 0.68'

-- uptime < 24 hours
-- e.g. '20:09  up  1:06, 3 users, load averages: 1.25 1.30 1.05'

-- uptime >= 24 hours
-- The three patterns are repeated, but with 'x day(s)' added in front.
-- e.g. '19:20  up 1 day, 3 mins, 2 users, load averages: 0.69 0.19 0.11'

on substitute()
	-- Take the output from 'uptime' and return the segment located between 'up' and ', x users'.
	return do shell script "/usr/bin/uptime | /usr/bin/awk -F'up[ ]+|, [0-9]+ user[s]*' '{print $2}'" as string
end substitute