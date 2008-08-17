/*!
	@header IntegerMath.h
	@brief Function to perform integer maths.
	
	Contains function that are integer version of float math opperations, e.g. <tt>log10I</tt> or function that are really only applicaple as integer opperations, e.g. <tt>greatestCommonDivisor</tt>

	Created by Nathan Day on Sun Jun 29 2003.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */

/*!
	@brief Returns the base 10 logarithm for <tt><i>num</i></tt>.
	
	@c log10I returns the largest integer less than 10 base logarithm of the unsigned long int <tt><i>num</i></tt>. It is equivelent to <code>(int)logf( num )</code>
	
	@param num The integer for which the logarithm is desired. 
	@return largest integer less than 10 base logarithm.
 */
unsigned short log10I( const unsigned long num );

/*!
	@brief Return the greatest common divisor
	
	The function @c greatestCommonDivisor returns the greatest common divisor of the two integers <tt><i>a</i></tt> and <tt><i>b</i></tt>.
	
	@param a A @c unsigned long int
	@param b A @c unsigned long int
	@return The greatest common divisor.
 */
unsigned long greatestCommonDivisor( unsigned long a, unsigned long b );
