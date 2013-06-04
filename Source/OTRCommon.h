/* libotr headers */

/* XXX: gcrypt has the nice habit of whining using deprecated datastructures
 * in their own code. This is meant to silence those.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import <libotr/proto.h>
#import <libotr/context.h>
#import <libotr/message.h>
#import <libotr/privkey.h>

#pragma clang diagnostic pop
