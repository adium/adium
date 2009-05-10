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

#import "AISoundController.h"

@interface AdiumSound : NSObject {
	NSMutableSet		*currentlyPlayingSounds;
	NSString			*outputDeviceUID;
	
    CGFloat				customVolume;
	
	NSUInteger			soundsAreMuted;

	BOOL				reconfigureAudioContextBeforeEachPlay;
}

/*!
 * @brief Finish Initing
 *
 * Requires:
 * 1) Preference controller is ready
 */
- (void)controllerDidLoad;

/*!
 * @brief Play a sound
 * 
 * @param inURL url to the sound file
 */
- (void)playSoundAtURL:(NSURL *)inURL;

/*!
 * @brief Stop playing a sound
 *
 * @par	Playback must have been started through \c AdiumSound; otherwise, the results are undefined.
 * 
 * @param inPath path to the sound file
 */
- (void)stopCurrentlyPlayingSounds;

/*!	@brief	Mute or unmute sounds.
 *
 *	@par	Calls to this method nest: If you call this method twice with \c YES, you must then call it twice with \c NO, or sounds will not be unmuted.
 *
 *	@param	mute	\c YES if you want sounds muted; \c NO if you want sounds unmuted.
 */
- (void)setSoundsAreMuted:(BOOL)mute;

@end
