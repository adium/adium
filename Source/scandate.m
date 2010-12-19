/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "scandate.h"

BOOL scandate(const char *sample,
					 unsigned long *outyear, unsigned long *outmonth,  unsigned long *outdate,
					 BOOL *outHasTime, unsigned long *outhour, unsigned long *outminute, unsigned long *outsecond,
					 long *outtimezone)
{
	BOOL success = YES;
	unsigned long component;

	const char *lastOpenParenthesis = NULL;

    //Read a '(', followed by a date.
	//First, find the '('.
	while (*sample != '\0') {
		if (*sample == '(')
			lastOpenParenthesis = sample;
		++sample;
    }

	if (!lastOpenParenthesis) {
		success = NO;
		goto fail;
	}
	sample = lastOpenParenthesis;

	//current character is a '(' now, so skip over it.
    ++sample; //start with the next character
	
    /*get the year*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outyear) *outyear = component;
    }
    
    /*get the month*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outmonth) *outmonth = component;
    }
    
    /*get the date*/ {
		while (*sample && (*sample < '0' || *sample > '9')) ++sample;
		if (!*sample) {
			success = NO;
			goto fail;
		}
		component = strtoul(sample, (char **)&sample, 10);
		if (outdate) *outdate = component;
    }

    if (*sample == 'T') {
		++sample; //start with the next character
		if (outHasTime) *outHasTime = YES;
		
		/*get the hour*/ {
			while (*sample && (*sample < '0' || *sample > '9')) ++sample;
			if (!*sample) {
				success = NO;
				goto fail;
			}
			component = strtoul(sample, (char **)&sample, 10);
			if (outhour) *outhour = component;
		}

		/*get the minute*/ {
			while (*sample && (*sample < '0' || *sample > '9')) ++sample;
			if (!*sample) {
				success = NO;
				goto fail;
			}
			component = strtoul(sample, (char **)&sample, 10);
			if (outminute) *outminute = component;
		}

		/*get the second*/ {
			while (*sample && (*sample < '0' || *sample > '9')) ++sample;
			if (!*sample) {
				success = NO;
				goto fail;
			}
			component = strtoul(sample, (char **)&sample, 10);
			if (outsecond) *outsecond = component;
		}

		/*get the time zone*/ {
			while (*sample && ((*sample < '0' || *sample > '9') && *sample != '-' && *sample != '+')) ++sample;
			if (!*sample) {
				success = NO;
				goto fail;
			}
			long timezone_sign = 1;
			if(*sample == '+') {
				++sample;
			} else if(*sample == '-') {
				timezone_sign = -1;
				++sample;
			} else if (*sample) {
				//There's something here, but it's not a time zone. Bail.
				success = NO;
				goto fail;
			}
			long timezone_hr = 0;
			if (*sample >= '0' || *sample <= '9') {
				timezone_hr += *(sample++) - '0';
			}
			if (*sample >= '0' || *sample <= '9') {
				timezone_hr *= 10;
				timezone_hr += *(sample++) - '0';
			}
			long timezone_min = 0;
			if (*sample >= '0' || *sample <= '9') {
				timezone_min += *(sample++) - '0';
			}
			if (*sample >= '0' || *sample <= '9') {
				timezone_min *= 10;
				timezone_min += *(sample++) - '0';
			}
			if (outtimezone) *outtimezone = (timezone_hr * 60 + timezone_min) * timezone_sign;
		}
	}
	
fail:
	return success;
}
