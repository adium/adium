//Localization
#ifndef AILocalizedString

	//Note that while NSLocalizedString() uses the main bundle, AILocalizedString() uses [self class]'s bundle
	#define AILocalizedString(key, comment) \
		AILocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)

	//Like NSLocalizedString(), AILocalizedString() looks to the main bundle
	#define AILocalizedStringFromTable(key, table, comment) \
		AILocalizedStringFromTableInBundle(key, table, [NSBundle mainBundle], comment)

	#define AILocalizedStringFromTableInBundle(key, table, bundle, comment) \
		NSLocalizedStringFromTableInBundle(key, table, bundle, comment)

#endif
