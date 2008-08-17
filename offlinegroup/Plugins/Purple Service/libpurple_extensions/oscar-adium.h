#include <libpurple/internal.h>

#include <libpurple/account.h>
#include <libpurple/accountopt.h>
#include <libpurple/buddyicon.h>
#include <libpurple/cipher.h>
#include <libpurple/conversation.h>
#include <libpurple/core.h>
#include <libpurple/debug.h>
#include <libpurple/ft.h>
#include <libpurple/imgstore.h>
#include <libpurple/network.h>
#include <libpurple/notify.h>
#include <libpurple/privacy.h>
#include <libpurple/prpl.h>
#include <libpurple/proxy.h>
#include <libpurple/request.h>
#include <libpurple/util.h>
#include <libpurple/version.h>

#include <libpurple/oscar.h>

void oscar_reformat_screenname(PurpleConnection *gc, const char *nick);
