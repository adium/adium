/*
 * yahoo_auth.h: Header for Yahoo Messenger authentication schemes.  Eew.
 *
 * Copyright(c) 2003 Cerulean Studios
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111-1301  USA
 *
 */

#ifndef _YAHOO_AUTH_H_
#define _YAHOO_AUTH_H_ 

#define NUM_TYPE_THREES 105
#define NUM_TYPE_FOURS 56
#define NUM_TYPE_FIVES 37

unsigned int yahoo_auth_finalCountdown(unsigned int challenge, int divisor, int inner_loop, int outer_loop);

/* We've defined the Yahoo authentication functions as having types 1-5; all take either 1 or 2 arguments.
 */

typedef struct _auth {
	int				type;
	int				var1; 
	int				var2;
} auth_function_t;

/* Type 3, 4 and 5 require lookups into ypager.exe's many static chunks of 256 bytes.  Store them here.
 */

struct buffer_t {
	unsigned int	buffer_start;
	unsigned char	buffer[257];
};

#endif /* _YAHOO_AUTH_H_ */
