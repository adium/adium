/*
 *  AIControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/30/06.
 *
 */

@protocol AIController <NSObject>
- (void)controllerDidLoad;
- (void)controllerWillClose;
@end
