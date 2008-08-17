/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIFunctions.h"
#include <sys/types.h>
#include <sys/mman.h>
#include <malloc/malloc.h>
#include <stdlib.h>

BOOL AIGetSurrogates(UTF32Char in, UTF16Char *outHigh, UTF16Char *outLow)
{
	if (in < 0x10000) {
		if (outHigh) *outHigh = 0;
		if (outLow)  *outLow  = in;
		return NO;
	} else {
		enum {
			UTF32LowShiftToUTF16High = 10,
			UTF32HighShiftToUTF16High,
			UTF16HighMask = 31,  //0b0000 0111 1100 0000
			UTF16LowMask  = 63,  //0b0000 0000 0011 1111
			UTF32LowMask = 1023, //0b0000 0011 1111 1111
			UTF16HighAdditiveMask = 55296, //0b1101 1000 0000 0000
			UTF16LowAdditiveMask  = 56320, //0b1101 1100 0000 0000
		};

		if (outHigh) {
			*outHigh = \
				  ((in >> UTF32HighShiftToUTF16High) & UTF16HighMask) \
				| ((in >> UTF32LowShiftToUTF16High) & UTF16LowMask) \
				| UTF16HighAdditiveMask;
		}

		if (outLow) {
			*outLow = (in & UTF32LowMask) | UTF16LowAdditiveMask;
		}

		return YES;
	}
}

//this uses the algorithm employed by Darwin 7.x's rm(1).
void AIWipeMemory(void *buf, size_t len)
{
	if (buf) {
		char *buf_char = buf;
		for (unsigned long i = 0; i < len; ++i) {
			buf_char[i] = 0xff;
			buf_char[i] = 0x00;
			buf_char[i] = 0xff;
		}
	}
}

void *AIReallocWired(void *oldBuf, size_t newLen)
{
	void *newBuf = malloc(newLen);
	if (!newBuf) {
		NSLog(@"in AIReallocWired: could not allocate %lu bytes", (unsigned long)newLen);
	} else {
		int mlock_retval = mlock(newBuf, newLen);
		if (mlock_retval < 0) {
			NSLog(@"in AIReallocWired: could not wire %lu bytes", (unsigned long)newLen);
			free(newBuf);
			newBuf = NULL;
		} else if (oldBuf) {
			size_t  oldLen = malloc_size(oldBuf);
			size_t copyLen = MIN(newLen, oldLen);

			memcpy(newBuf, oldBuf, copyLen);

			AIWipeMemory(oldBuf, oldLen);
			munlock(oldBuf, oldLen);
			free(oldBuf);
		}
	}
	return newBuf;
}

void AISetRangeInMemory(void *buf, NSRange range, int ch)
{
	unsigned i     = range.location;
	unsigned i_max = range.location + range.length;
	char *buf_ch = buf;
	while (i < i_max) {
		buf_ch[i++] = ch;
	}
}

#pragma mark Rect utilities

float AICoordinateForRect_edge_(const NSRect rect, const NSRectEdge edge)
{
	float coordinate = 0.0;
	switch (edge) {
		case NSMinXEdge : coordinate = NSMinX(rect); break;
		case NSMinYEdge : coordinate = NSMinY(rect); break;
		case NSMaxXEdge : coordinate = NSMaxX(rect); break;
		case NSMaxYEdge : coordinate = NSMaxY(rect); break;
	}
	
	return coordinate;
}

// returns the distance that a point lies outside a rect on a particular side.  If the point lies 
// on the interior side of the edge, the number returned will be negative
float AISignedExteriorDistanceRect_edge_toPoint_(const NSRect rect, const NSRectEdge edge, const NSPoint point)
{
	float distanceOutside = 0.0;
	float rectEdgeCoordinate = AICoordinateForRect_edge_(rect, edge);
	switch (edge) {
		case NSMinXEdge: distanceOutside = rectEdgeCoordinate - point.x; break;
		case NSMaxXEdge: distanceOutside = point.x - rectEdgeCoordinate; break;
		case NSMinYEdge: distanceOutside = rectEdgeCoordinate - point.y; break;
		case NSMaxYEdge: distanceOutside = point.y - rectEdgeCoordinate; break;
	}
	
	return distanceOutside;
}

NSRectEdge AIOppositeRectEdge_(const NSRectEdge edge)
{
	NSRectEdge oppositeEdge = AINotARectEdge;

	switch (edge) {
		case NSMinXEdge: oppositeEdge = NSMaxXEdge; break;
		case NSMinYEdge: oppositeEdge = NSMaxYEdge; break;
		case NSMaxXEdge: oppositeEdge = NSMinXEdge; break;
		case NSMaxYEdge: oppositeEdge = NSMinYEdge; break;
	}
	
	return oppositeEdge;	
}

// translate mobileRect so that it aligns with stationaryRect
// undefined if aligning left to top or something else that does not make sense
NSRect AIRectByAligningRect_edge_toRect_edge_(NSRect mobileRect, const NSRectEdge mobileRectEdge, const NSRect stationaryRect, const NSRectEdge stationaryRectEdge)
{
	float alignToCoordinate = AICoordinateForRect_edge_(stationaryRect, stationaryRectEdge);
	switch (mobileRectEdge) {
		case NSMinXEdge: mobileRect.origin.x = alignToCoordinate; break;
		case NSMinYEdge: mobileRect.origin.y = alignToCoordinate; break;
		case NSMaxXEdge: mobileRect.origin.x = alignToCoordinate - NSWidth(mobileRect); break;
		case NSMaxYEdge: mobileRect.origin.y = alignToCoordinate - NSHeight(mobileRect); break;
	}
	
	return mobileRect;
}

BOOL AIRectIsAligned_edge_toRect_edge_tolerance_(const NSRect rect1, const NSRectEdge edge1, const NSRect rect2, const NSRectEdge edge2, const float tolerance)
{
	return fabsf(AICoordinateForRect_edge_(rect1, edge1) - AICoordinateForRect_edge_(rect2, edge2)) < tolerance;
}

// minimally translate mobileRect so that it lies within stationaryRect
NSRect AIRectByMovingRect_intoRect_(NSRect mobileRect, const NSRect stationaryRect)
{
	mobileRect.origin.x = MAX(mobileRect.origin.x, NSMinX(stationaryRect));
	mobileRect.origin.y = MAX(mobileRect.origin.y, NSMinY(stationaryRect));
	mobileRect.origin.x = MIN(mobileRect.origin.x, NSMaxX(stationaryRect) - NSWidth(mobileRect));
	mobileRect.origin.y = MIN(mobileRect.origin.y, NSMaxY(stationaryRect) - NSHeight(mobileRect));
	
	return mobileRect;
}

