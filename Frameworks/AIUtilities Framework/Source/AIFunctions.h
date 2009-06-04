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

#pragma mark Rect utilities
/*!	@defgroup AIRectUtilities Rectangle utilities
 *
 *	Functions for managing the placement and alignment of rectangles relative to other rectangles.
 */
/*@{*/

/*!	@enum AIRectEdgeMask
 *	A bit mask of zero or more edges of a rectangle.
 */
typedef enum AIRectEdgeMask {
	//!No edges.
	AINoEdges = 0,
	//!Far right.
	AIMaxXEdgeMask	= (1 << NSMaxXEdge),
	//!Top.
	AIMaxYEdgeMask	= (1 << NSMaxYEdge),
	//!Far left.
	AIMinXEdgeMask	= (1 << NSMinXEdge),
	//!Bottom.
	AIMinYEdgeMask	= (1 << NSMinYEdge)
} AIRectEdgeMask;

enum {
	//!This value in an NSRectEdge variable indicates no edge.
	AINotARectEdge = -1
};

/*!	@brief Returns the coordinate for an edge of a rectangle.
 *
 *	For example, AICoordinateForRect_edge_(rect, NSMaxXEdge) is the same as NSMaxX(rect).
 *
 *	@return An X or Y coordinate.
 */
float AICoordinateForRect_edge_(NSRect rect, NSRectEdge edge);

/*!	@brief Measures a line from \a edge to \a point.
 *
 *	Returns the distance that \a point lies outside of \a rect on a particular side (\a edge).
 *	If the point lies on the interior side of that edge, the number returned will be negative, even if the point is outside the rectangle itself.
 *	For example, if \c rect.origin.x is 50, and \c rect.size.width is 50, and \c point.x is 25, and \a edge is \c NSMaxXEdge, the result will be -75.0f.
 *
 *	@return The distance between the edge and the point. It is positive if the point is outside the edge, negative if it is inside the edge (even it is outside the rectangle).
 */
float AISignedExteriorDistanceRect_edge_toPoint_(NSRect rect, NSRectEdge edge, NSPoint point);

/*!	@brief Returns the edge that would be across a rectangle from \a edge.
 *
 *	For example, AIOppositeRectEdge_(NSMaxXEdge) is NSMinXEdge.
 *
 *	@return An edge.
 */
NSRectEdge AIOppositeRectEdge_(NSRectEdge edge);

// translate mobileRect so that it aligns with stationaryRect
// undefined if aligning left to top or something else that does not make sense
NSRect AIRectByAligningRect_edge_toRect_edge_(NSRect mobileRect, 
											  NSRectEdge mobileRectEdge, 
											  NSRect stationaryRect, 
											  NSRectEdge stationaryRectEdge);

/*!	@brief Returns whether \a edge1 of \a rect1 is within \a tolerance units of \a edge2 of \a rect2.
 *	@return \c YES if the distance between the two edges is less than \a tolerance; \c NO if not.
 */
BOOL AIRectIsAligned_edge_toRect_edge_tolerance_(NSRect rect1, 
												 NSRectEdge edge1, 
												 NSRect rect2, 
												 NSRectEdge edge2, 
												 float tolerance);

// minimally translate mobileRect so that it lies within stationaryRect
NSRect AIRectByMovingRect_intoRect_(NSRect mobileRect, NSRect stationaryRect);

/*@}*/
