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

/*Input: A string in UTF-8 encoding containing an ISO 8601 date within a parenthesis.
 *Output:
 *- Year, month, and date
 *- Whether time was found
 *- The hour, minute, and second of that time
 *- The time zone offset as a single number of minutes
 *- (Return value) Whether a date was found.
 */
BOOL scandate(const char *sample,
              unsigned long *outyear, unsigned long *outmonth,  unsigned long *outdate,
              BOOL *outHasTime, unsigned long *outhour, unsigned long *outminute, unsigned long *outsecond,
              long *outtimezone);
