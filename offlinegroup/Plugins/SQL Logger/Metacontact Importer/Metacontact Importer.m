#import <Foundation/Foundation.h>
#import <libpq-fe.h>

#pragma mark Keys and filenames

#define KEY_SQL_USERNAME			@"Username"
#define KEY_SQL_PASSWORD			@"Password"
#define KEY_SQL_URL					@"URL"
#define KEY_SQL_PORT				@"Port"
#define KEY_SQL_DATABASE			@"Database"

#define KEY_METACONTACTS			@"MetaContact Ownership"
#define CONTACTLIST_PREFS			@"Contact List.plist"

#define KEY_PREFERRED				@"Preferred Destination Contact"

#define KEY_SERVICE					@"ServiceID"
#define KEY_UID						@"UID"

#define KEY_ALIAS					@"Alias"

#pragma mark Interfaces

PGconn * conn;

void loadMetaContacts(NSString * userDir);

void insertMetaContact(NSString * userDir, NSString * ID, NSArray * users);

NSDictionary * metaContactsDictionary(NSString * userDir);
NSDictionary * dictionaryForObject(NSString * userDir, NSString * object);

// ------- PQ

void openDatabase(NSString * userDir);
void closeDatabase();

int createMetaContact(NSString * name);
void addUserToContact(int contactID, NSString * service, NSString * username, BOOL preferred);

char * escapeString(NSString * str);

#pragma mark Implementations

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString * adiumUsersDirectory = [@"~/Library/Application Support/Adium 2.0/Users" stringByExpandingTildeInPath];
	NSArray * users = [[NSFileManager defaultManager] directoryContentsAtPath:adiumUsersDirectory];
	
	NSEnumerator * e = [users objectEnumerator];
	NSString * user;
	
	while((user = [e nextObject]))
	{
		if([user hasPrefix:@"."]) continue;
		NSLog(@"Loading for user: %@",user);
		loadMetaContacts([adiumUsersDirectory stringByAppendingPathComponent:user]);
	}
	
    [pool release];
    return 0;
}

void loadMetaContacts(NSString * userDir)
{
	openDatabase(userDir);
	NSDictionary * metaContacts = metaContactsDictionary(userDir);
	NSEnumerator * e = [metaContacts keyEnumerator];
	NSString * contact;
	
	while((contact = [e nextObject]))
	{
		if([[metaContacts objectForKey:contact] count] > 1)
		{
			insertMetaContact(userDir, contact, [metaContacts objectForKey:contact]);
		}
	}
	closeDatabase();
}

void insertMetaContact(NSString * userDir, NSString * ID, NSArray * users)
{
	NSDictionary * metaDict;
	NSArray		* preferredContact;
	NSString	* preferredService = nil, 
				* preferredUID = nil;
	NSString	* alias;
	NSEnumerator * e;
	NSDictionary * contact;
	int metaID;
	
	PQexec(conn,"BEGIN");
	
	metaDict = dictionaryForObject(userDir, ID);

	preferredContact = [[metaDict objectForKey:KEY_PREFERRED] componentsSeparatedByString:@"."];	
	if(preferredContact)
	{
		preferredService = [preferredContact objectAtIndex:0];
		preferredUID = [preferredContact objectAtIndex:1];
	}
	
	alias =  [metaDict objectForKey:KEY_ALIAS];
	if(!alias)
	{
		e = [users objectEnumerator];
		while((contact = [e nextObject]))
		{
			contact = 
			   dictionaryForObject(userDir, [NSString stringWithFormat:@"%@.%@",
						[contact objectForKey:KEY_SERVICE],[contact objectForKey:KEY_UID]]);
			if(alias = [contact objectForKey:KEY_ALIAS])
				break;
		}
		if(!alias) alias = @"<No name>";
	}
	
	metaID = createMetaContact(alias);
	if(metaID < 0)
	{
		PQexec(conn,"ROLLBACK");
		return;
	}
	NSLog(@"Creating meta contact %@ with id %d", alias, metaID);
	
	e = [users objectEnumerator];
	while((contact = [e nextObject]))
	{
		NSString * service, * uid;
		service = [contact objectForKey:KEY_SERVICE];
		uid = [contact objectForKey:KEY_UID];
		
		NSLog(@"Inserting meta contact user: %@.%@",service,uid);
		addUserToContact(metaID, service, uid, [uid isEqual:preferredUID] && [service isEqual:preferredService]);
	}
	
	PQexec(conn,"COMMIT");
}

NSDictionary * metaContactsDictionary(NSString * userDir)
{
	NSDictionary * contactList = [NSDictionary dictionaryWithContentsOfFile:[userDir stringByAppendingPathComponent:CONTACTLIST_PREFS]];
	return [contactList objectForKey:KEY_METACONTACTS];
}

NSDictionary * dictionaryForObject(NSString * userDir, NSString * object)
{
	return [NSDictionary dictionaryWithContentsOfFile:
		[[[userDir stringByAppendingPathComponent:@"ByObject"] stringByAppendingPathComponent:object] 
			stringByAppendingPathExtension:@"plist"]];
}

#pragma mark PQ code

void openDatabase(NSString * userDir)
{
	NSDictionary * prefs = [NSDictionary dictionaryWithContentsOfFile:[userDir stringByAppendingPathComponent:@"SQLLogging.plist"]];
	NSString	* connInfo;
	NSString	* tmp;
	
	NSString	* host = @"",
		* port = @"",
		* user = NSUserName(),
		* pass = @"",
		* database = NSUserName();
	
	if(prefs)
	{
		tmp = [prefs objectForKey:KEY_SQL_URL];
		if(tmp) host = tmp;
		tmp = [prefs objectForKey:KEY_SQL_PORT];
		if(tmp) port = tmp;
		tmp = [prefs objectForKey:KEY_SQL_USERNAME];
		if(tmp) user = tmp;
		tmp = [prefs objectForKey:KEY_SQL_PASSWORD];
		if(tmp) pass = tmp;
		tmp = [prefs objectForKey:KEY_SQL_DATABASE];
		if(tmp) database = tmp;
	}
	
	connInfo = [NSString stringWithFormat:@"host=\'%@\' port=\'%@\' user=\'%@\' password=\'%@\' dbname=\'%@\' sslmode=\'prefer\'",
		host, port, user, pass, database];
	
	conn = PQconnectdb([connInfo cString]);
    if (PQstatus(conn) == CONNECTION_BAD)
    {
        NSString *error =  [NSString stringWithCString:PQerrorMessage(conn)];
		NSLog(@"Error connecting: %@",error);
		exit(-1);
    }	
}

void closeDatabase()
{
	PQfinish(conn);
}

int createMetaContact(NSString * name)
{
	char * nameEscape;
	NSString * sql;
	PGresult * res;
	
	nameEscape = escapeString(name);
	sql = [NSString stringWithFormat:@"INSERT INTO im.meta_container (meta_id,name) VALUES (nextval(\'im.meta_container_meta_id_seq\'),\'%s\')", nameEscape];
	res = PQexec(conn, [sql UTF8String]);

	free(nameEscape);
	
	if(!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		NSLog(@"Error inserting: %s",PQresultErrorMessage(res));
		PQclear(res);
		return -1;
	}
	else
	{
		int metaID;
		PQclear(res);
		res = PQexec(conn, "SELECT currval(\'im.meta_container_meta_id_seq\')");
		if(!res || PQresultStatus(res) != PGRES_TUPLES_OK)
		{
			NSLog(@"Error fetching currval: %s / %s",PQresStatus(PQresultStatus(res)), PQresultErrorMessage(res));
			PQclear(res);
			return -1;
		}
		metaID = atoi(PQgetvalue(res,0,0));
		PQclear(res);
		return metaID;
	}	
}

void addUserToContact(int metaID, NSString * service, NSString * username, BOOL preferred)
{
	char * serviceEscape;
	char * usernameEscape;
	NSString * sql;
	PGresult * res;
	
	if([service isEqualToString:@"Mac"])
		service = @"AIM";
	
	serviceEscape = escapeString(service);
	usernameEscape = escapeString(username);
	
	sql = [NSString stringWithFormat:@"INSERT INTO im.meta_contact(meta_id,user_id,preferred) SELECT %d,user_id,%s FROM im.Users WHERE service = \'%s\' AND username=\'%s\'",
					metaID, preferred?"true":"false", serviceEscape,usernameEscape];

	free(serviceEscape);
	free(usernameEscape);
	
	res = PQexec(conn, [sql UTF8String]);
	
	if(!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		NSLog(@"Error: %s",PQresultErrorMessage(res));
	}
	
	PQclear(res);	
}

char * escapeString(NSString * str)
{
	char * outstring = malloc([str length]*2 + 1);
	PQescapeString(outstring, [str UTF8String], [str length]);
	
	return outstring;
}
