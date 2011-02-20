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

#import "AIFunctions.h"

#pragma mark Rect utilities

CGFloat AICoordinateForRect_edge_(const NSRect rect, const NSRectEdge edge)
{
	CGFloat coordinate = 0.0f;
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
CGFloat AISignedExteriorDistanceRect_edge_toPoint_(const NSRect rect, const NSRectEdge edge, const NSPoint point)
{
	CGFloat distanceOutside = 0.0f;
	CGFloat rectEdgeCoordinate = AICoordinateForRect_edge_(rect, edge);
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
	CGFloat alignToCoordinate = AICoordinateForRect_edge_(stationaryRect, stationaryRectEdge);
	switch (mobileRectEdge) {
		case NSMinXEdge: mobileRect.origin.x = alignToCoordinate; break;
		case NSMinYEdge: mobileRect.origin.y = alignToCoordinate; break;
		case NSMaxXEdge: mobileRect.origin.x = alignToCoordinate - NSWidth(mobileRect); break;
		case NSMaxYEdge: mobileRect.origin.y = alignToCoordinate - NSHeight(mobileRect); break;
	}
	
	return mobileRect;
}

BOOL AIRectIsAligned_edge_toRect_edge_tolerance_(const NSRect rect1, const NSRectEdge edge1, const NSRect rect2, const NSRectEdge edge2, const CGFloat tolerance)
{
	return AIfabs(AICoordinateForRect_edge_(rect1, edge1) - AICoordinateForRect_edge_(rect2, edge2)) < tolerance;
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

