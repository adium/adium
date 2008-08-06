#import "oscar-adium.h"

void oscar_reformat_screenname(PurpleConnection *gc, const char *nick) {
	OscarData *od = gc->proto_data;
	if (!aim_sncmp(purple_account_get_username(purple_connection_get_account(gc)), nick)) {
		if (!flap_connection_getbytype(od, SNAC_FAMILY_ADMIN)) {
			od->setnick = TRUE;
			od->newsn = g_strdup(nick);
			aim_srv_requestnew(od, SNAC_FAMILY_ADMIN);
		} else {
			aim_admin_setnick(od, flap_connection_getbytype(od, SNAC_FAMILY_ADMIN), nick);
		}
	}
}
