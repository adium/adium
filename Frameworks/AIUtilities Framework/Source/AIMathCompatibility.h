/*
 *  AIMathCompatibility.h
 *  Adium
 *
 *  Created by Stephen Holt on 12/23/09.
 *  Copyright 2009. All rights reserved.
 *
 */

#ifndef AIMathCompatibility
#define AIMathCompatibility 1

#if __LP64__ || NS_BUILD_32_LIKE_64
	#define AIfabs( X )			fabs((X))
	#define AIround( X )		round((X))
	#define AIceil( X )			ceil((X))
	#define AIfloor( X )		floor((X))
	#define AIfmod( X, Y )	fmod((X),(Y))
	#define AIfmin( X, Y )	fmin((X),(Y))
	#define AIsqrt( X )			sqrt((X))

	#define AIsin( X )			sin((X))
	#define AIcos( X )			cos((X))
	#define AIatan2( X, Y )	atan2((X),(Y))
#else
	#define AIfabs( X )			fabsf((X))
	#define AIround( X )		roundf((X))
	#define AIceil( X )			ceilf((X))
	#define AIfloor( X )		floorf((X))
	#define AIfmod( X, Y )	fmodf((X),(Y))
	#define AIfmin( X, Y )	fminf((X),(Y))
	#define AIsqrt( X )			sqrtf((X))

	#define AIsin( X )			sinf((X))
	#define AIcos( X )			cosf((X))
	#define AIatan2( X, Y )	atan2f((X),(Y))
#endif

#endif
