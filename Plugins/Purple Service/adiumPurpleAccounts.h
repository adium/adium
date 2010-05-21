//
//  adiumPurpleAccounts.h
//  Adium
//
//  Created by Evan Schoenberg on 12/3/06.


#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

PurpleAccountUiOps *adium_purple_accounts_get_ui_ops(void);

void didCloseAccountRequest(void *ui_handle);
void adiumPurpleAccountRegisterCb(PurpleAccount *account, gboolean succeeded, void *user_data);
