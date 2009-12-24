/*
 *  AIMathCompatibility.h
 *  Adium
 *
 *  Created by Stephen Holt on 12/23/09.
 *  Copyright 2009. All rights reserved.
 *
 */

#ifndef AIMathCompatibility
#define AIMathCompatibility

#ifdef __LP64__
	#define AIfabs( X ) fabs((X))
	#define AIround( X ) round((X))
	#define AIceil( X ) ceil((X))
	#define AIfloor( X ) floor((X))
	#define AIfmod( X, Y ) fmod((X),(Y))
#else
	#define AIfabs( X ) fabsf((X))
	#define AIround( X ) roundf((X))
	#define AIceil( X ) ceilf((X))
	#define AIfloor( X ) floorf((X))
	#define AIfmod( X, Y ) fmodf((X),(Y))
#endif

#endif
