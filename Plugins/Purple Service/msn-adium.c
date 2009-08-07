/* This file adds msn_set_friendly_name() which is needed when using the *old* MSN protocol in libpurple.
 * It is not needed in the new version of the protocol, which provides msn_act_id() to perform the same function.
 */

#define BUDDY_ALIAS_MAXLEN 387

#include <glib.h>

#include "msn.h"
#include "accountopt.h"
#include "msg.h"
#include "page.h"
#include "pluginpref.h"
#include "prefs.h"
#include "session.h"
#include "state.h"
#include "msn-utils.h"
#include "cmds.h"
#include "prpl.h"
#include "util.h"
#include "version.h"

#include "switchboard.h"
#include "notification.h"
#include "sync.h"
#include "slplink.h"

#import "PurpleCommon.h"

void msn_set_friendly_name(PurpleConnection *gc, const char *entry)
{
	MsnCmdProc *cmdproc;
	MsnSession *session;
	PurpleAccount *account;
	const char *alias;
	
	session = gc->proto_data;
	cmdproc = session->notification->cmdproc;
	account = purple_connection_get_account(gc);
	
	if(entry && strlen(entry))
		alias = purple_url_encode(entry);
	else
		alias = "";
	
	if (strlen(alias) > BUDDY_ALIAS_MAXLEN)
	{
		purple_notify_error(gc, NULL,
						  _("Your new MSN friendly name is too long."), NULL);
		return;
	}
	
	msn_cmdproc_send(cmdproc, "REA", "%s %s",
					 purple_account_get_username(account),
					 alias);
}
