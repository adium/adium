//
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"

#import "NSData+Base64.h"

#define USE_LIBXML 0

#import "MGTwitterStatusesParser.h"
#import "MGTwitterUsersParser.h"
#import "MGTwitterMessagesParser.h"
#import "MGTwitterMiscParser.h"

#define TWITTER_DOMAIN          @"api.twitter.com/1"
#define HTTP_POST_METHOD        @"POST"
#define HTTP_MULTIPART_METHOD	@"MULTIPART" //adium
#define MULTIPART_FORM_BOUNDARY	@"bf5faadd239c17e35f91e6dafe1d2f96" //adium
#define MAX_MESSAGE_LENGTH      140 // Twitter recommends tweets of max 140 chars
#define MAX_LOCATION_LENGTH		31

#define DEFAULT_CLIENT_NAME     @"MGTwitterEngine"
#define DEFAULT_CLIENT_VERSION  @"1.0"
#define DEFAULT_CLIENT_URL      @"http://mattgemmell.com/source"
#define DEFAULT_CLIENT_TOKEN	@"mgtwitterengine"

#define URL_REQUEST_TIMEOUT     50.0 // Twitter usually fails quickly if it's going to fail at all.
#define DEFAULT_TWEET_COUNT		20


@interface MGTwitterEngine (PrivateMethods)

// Utility methods
- (NSDateFormatter *)_HTTPDateFormatter;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSDate *)_HTTPToDate:(NSString *)httpDate;
- (NSString *)_dateToHTTP:(NSDate *)date;
- (NSString *)_encodeString:(NSString *)string;

// Connection/Request methods
- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(id)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType;

// Parsing methods
- (void)_parseXMLForConnection:(MGTwitterHTTPURLConnection *)connection;

// Delegate methods
- (BOOL) _isValidDelegateForSelector:(SEL)selector;

@end


@implementation MGTwitterEngine


#pragma mark Constructors


+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)theDelegate
{
    return [[MGTwitterEngine alloc] initWithDelegate:theDelegate];
}


- (MGTwitterEngine *)initWithDelegate:(NSObject <MGTwitterEngineDelegate> *)newDelegate
{
    if ((self = [super init])) {
        _delegate = newDelegate; // deliberately weak reference
        _connections = [[NSMutableDictionary alloc] initWithCapacity:0];
        _clientName = DEFAULT_CLIENT_NAME;
        _clientVersion = DEFAULT_CLIENT_VERSION;
        _clientURL = DEFAULT_CLIENT_URL;
		_clientSourceToken = DEFAULT_CLIENT_TOKEN;
		_APIDomain = TWITTER_DOMAIN;
        _secureConnection = YES;
		_clearsCookies = NO;
    }
    
    return self;
}


- (void)dealloc
{
    _delegate = nil;
    
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
}


#pragma mark Configuration and Accessors


+ (NSString *)version
{
    // 1.0.0 = 22 Feb 2008
    // 1.0.1 = 26 Feb 2008
    // 1.0.2 = 04 Mar 2008
    // 1.0.3 = 04 Mar 2008
	// 1.0.4 = 11 Apr 2008
	// 1.0.5 = 06 Jun 2008
	// 1.0.6 = 05 Aug 2008
	// 1.0.7 = 28 Sep 2008
	// 1.0.8 = 01 Oct 2008
    return @"1.0.8";
}


- (NSString *)username
{
    return _username;
}


- (NSString *)password
{
    return _password;
}


- (void)setUsername:(NSString *)newUsername password:(NSString *)newPassword
{
    // Set new credentials.
    _username = newUsername;
    _password = newPassword;
    
	if ([self clearsCookies]) {
		// Remove all cookies for twitter, to ensure next connection uses new credentials.
		NSString *urlString = [NSString stringWithFormat:@"%@://%@", 
							   (_secureConnection) ? @"https" : @"http", 
							   _APIDomain];
		NSURL *url = [NSURL URLWithString:urlString];
		
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSEnumerator *enumerator = [[cookieStorage cookiesForURL:url] objectEnumerator];
		NSHTTPCookie *cookie = nil;
		while ((cookie = [enumerator nextObject])) {
			[cookieStorage deleteCookie:cookie];
		}
	}
}


- (NSString *)clientName
{
    return _clientName;
}


- (NSString *)clientVersion
{
    return _clientVersion;
}


- (NSString *)clientURL
{
    return _clientURL;
}


- (NSString *)clientSourceToken
{
    return _clientSourceToken;
}


- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
{
    _clientName = name;
    _clientVersion = version;
    _clientURL = url;
    _clientSourceToken = token;
}


- (NSString *)APIDomain
{
	return _APIDomain;
}


- (void)setAPIDomain:(NSString *)domain
{
	if (!domain || [domain length] == 0) {
		_APIDomain = TWITTER_DOMAIN;
	} else {
		_APIDomain = domain;
	}
}


- (BOOL)usesSecureConnection
{
    return _secureConnection;
}


- (void)setUsesSecureConnection:(BOOL)flag
{
    _secureConnection = flag;
}


- (BOOL)clearsCookies
{
	return _clearsCookies;
}


- (void)setClearsCookies:(BOOL)flag
{
	_clearsCookies = flag;
}


#pragma mark Connection methods


- (NSUInteger)numberOfConnections
{
    return [_connections count];
}


- (NSArray *)connectionIdentifiers
{
    return [_connections allKeys];
}


- (void)closeConnection:(NSString *)identifier
{
    MGTwitterHTTPURLConnection *connection = [_connections objectForKey:identifier];
    if (connection) {
        [connection cancel];
        [_connections removeObjectForKey:identifier];
    }
}


- (void)closeAllConnections
{
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections removeAllObjects];
}


#pragma mark Utility methods


- (NSDateFormatter *)_HTTPDateFormatter
{
    // Returns a formatter for dates in HTTP format (i.e. RFC 822, updated by RFC 1123).
    // e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	//[dateFormatter setDateFormat:@"%a, %d %b %Y %H:%M:%S GMT"]; // won't work with -init, which uses new (unicode) format behaviour.
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss GMT"];
	return dateFormatter;
}


- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
    if (params) {
        int i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
             name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}


- (NSDate *)_HTTPToDate:(NSString *)httpDate
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter dateFromString:httpDate];
}


- (NSString *)_dateToHTTP:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter stringFromDate:date];
}


- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                 (__bridge CFStringRef)string, 
                                                                 NULL, 
                                                                 (CFStringRef)@";/?:@&=$+{}<>,",
                                                                 kCFStringEncodingUTF8);
    return result;
}


- (NSString *)getImageAtURL:(NSString *)urlString
{
    // This is a method implemented for the convenience of the client, 
    // allowing asynchronous downloading of users' Twitter profile images.
	NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!url) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
	[theRequest setHTTPShouldHandleCookies:NO];
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:MGTwitterImageRequest 
                                                        responseType:MGTwitterImage];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
    }
    
    return [connection identifier];
}


#pragma mark Request sending methods

#define SET_AUTHORIZATION_IN_HEADER 1

/* See Adium Additions/Changes below—oauth support */
#if 0
- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(id)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{
    // Construct appropriate URL string.
    NSString *fullPath = path;
    if (params) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
	
#if SET_AUTHORIZATION_IN_HEADER
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
                           (_secureConnection) ? @"https" : @"http",
                           _APIDomain, fullPath];
#else    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@", 
                           (_secureConnection) ? @"https" : @"http", 
                           [self _encodeString:_username], [self _encodeString:_password], 
                           _APIDomain, fullPath];
#endif
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:finalURL 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
	[theRequest setHTTPShouldHandleCookies:NO];
	if(method && [method isEqualToString:HTTP_MULTIPART_METHOD]) {
		method = HTTP_POST_METHOD;
		[theRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIPART_FORM_BOUNDARY] forHTTPHeaderField:@"Content-type"];
	}
	
    if (method) {
        [theRequest setHTTPMethod:method];
    }

    [theRequest setHTTPShouldHandleCookies:NO];
	
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
    
#if SET_AUTHORIZATION_IN_HEADER
	if ([self username] && [self password]) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [self username], [self password]];
		NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	}
#endif

    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
	
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
		if([body isKindOfClass:[NSString class]]) {
			NSString *finalBody = @"";
			if (body) {
				finalBody = [finalBody stringByAppendingString:body];
			}
			if (_clientSourceToken) {
				finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
																(body) ? @"&" : @"?" , 
																_clientSourceToken]];
			}
			
			if (finalBody) {
				[theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
			}
		} else if ([body isKindOfClass:[NSData class]]) {
			[theRequest setHTTPBody:body];
		}
    }
    
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
    
    return [connection identifier];
}
#endif

#pragma mark Parsing methods


- (void)_parseXMLForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSString *identifier = [[connection identifier] copy];
    NSData *xmlData = [[connection data] copy];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];
    
#if USE_LIBXML
	NSURL *URL = [connection URL];

    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersLibXMLParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType URL:URL];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscLibXMLParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL];
			break;
        default:
            break;
    }
#else
    // Determine which type of parser to use.
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType];
			break;
        default:
            break;
    }
#endif
}

#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}

#pragma mark MGTwitterParserDelegate methods


- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(MGTwitterResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
    // Forward appropriate message to _delegate, depending on responseType.
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
			if ([self _isValidDelegateForSelector:@selector(statusesReceived:forRequest:)])
				[_delegate statusesReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
			if ([self _isValidDelegateForSelector:@selector(userInfoReceived:forRequest:)])
				[_delegate userInfoReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
			if ([self _isValidDelegateForSelector:@selector(directMessagesReceived:forRequest:)])
				[_delegate directMessagesReceived:parsedObjects forRequest:identifier];
            break;
		case MGTwitterMiscellaneous:
			if ([self _isValidDelegateForSelector:@selector(miscInfoReceived:forRequest:)])
				[_delegate miscInfoReceived:parsedObjects forRequest:identifier];
			break;
        default:
            break;
    }
}


- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType 
                      withError:(NSError *)error
{
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:requestIdentifier withError:error];
}


#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0 && ![challenge proposedCredential] && !_useOAuth && _password && _username) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:_username password:_password 
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [resp statusCode];
    
    if (statusCode >= 400) {
        // Assume failure, and report to delegate.
        NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil];
		if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
			[_delegate requestFailed:[connection identifier] withError:error];
        
        // Destroy the connection.
        [connection cancel];
        [_connections removeObjectForKey:[connection identifier]];
        
    } else if (statusCode == 304 || [connection responseType] == MGTwitterGeneric) {
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                              ofResponseType:[connection responseType] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
        [_connections removeObjectForKey:[connection identifier]];
    }
    
    if (NO) {
        // Display headers for debugging.
        NSHTTPURLResponse *noResp = (NSHTTPURLResponse *)response;
        NSLog(@"(%ld) [%@]:\r%@", 
              (long)[noResp statusCode], 
              [NSHTTPURLResponse localizedStringForStatusCode:[noResp statusCode]], 
              [noResp allHeaderFields]);
    }
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:[connection identifier] withError:error];
    
    // Release the connection.
    [_connections removeObjectForKey:[connection identifier]];
}


- (void)connectionDidFinishLoading:(MGTwitterHTTPURLConnection *)connection
{
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:[connection identifier]];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
        if (NO) {
            // Dump data as string for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            NSLog(@"Succeeded! Received %lu bytes of data:\r\r%@", (unsigned long)[receivedData length], dataString);
        }
        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            [dataString writeToFile:[@"~/Desktop/twitter_messages.xml" stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUnicodeStringEncoding error:NULL];
        }
        
        if ([connection responseType] == MGTwitterImage) {
			// Create image from data.
#if TARGET_OS_IPHONE
            UIImage *image = [[[UIImage alloc] initWithData:[connection data]] autorelease];
#else
            NSImage *image = [[NSImage alloc] initWithData:[connection data]];
#endif
            
            // Inform delegate.
			if ([self _isValidDelegateForSelector:@selector(imageReceived:forRequest:)])
				[_delegate imageReceived:image forRequest:[connection identifier]];
        } else {
            // Parse XML appropriately.
            [self _parseXMLForConnection:connection];
        }
    }
    
    // Release the connection.
    [_connections removeObjectForKey:[connection identifier]];
}


#pragma mark -
#pragma mark Twitter API methods
#pragma mark -


#pragma mark Account methods

- (NSString *)endUserSession
{
    NSString *path = @"account/end_session"; // deliberately no format specified
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}


- (NSString *)enableUpdatesFor:(NSString *)username
{
    // i.e. follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/create/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableUpdatesFor:(NSString *)username
{
    // i.e. no longer follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/destroy/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2
{
	if (!username1 || !username2) {
        return nil;
    }
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:username1 forKey:@"user_a"];
	[params setObject:username2 forKey:@"user_b"];
	
    NSString *path = @"friendships/exists.xml";
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterMiscellaneous];
}


- (NSString *)enableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/follow/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/leave/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getRateLimitStatus
{
	NSString *path = @"account/rate_limit_status.xml";
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterMiscellaneous];
}


- (NSString *)setLocation:(NSString *)location
{
	if (!location) {
        return nil;
    }
    
    NSString *path = @"account/update_location.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:location forKey:@"location"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:nil body:body 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}


- (NSString *)setNotificationsDeliveryMethod:(NSString *)method
{
	NSString *deliveryMethod = method;
	if (!method || [method length] == 0) {
		deliveryMethod = @"none";
	}
	
	NSString *path = @"account/update_delivery_device.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (deliveryMethod) {
        [params setObject:deliveryMethod forKey:@"device"];
    }
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterGeneric];
}


- (NSString *)block:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/create/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterUser];
}


- (NSString *)unblock:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/destroy/%@.xml", username];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterUser];
}


- (NSString *)testService
{
	NSString *path = @"help/test.xml";
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterGeneric];
}


- (NSString *)getDowntimeSchedule
{
	NSString *path = @"help/downtime_schedule.xml";
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterMiscellaneous];
}


#pragma mark Retrieving updates


- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum
{
	// Included for backwards-compatibility.
    return [self getFollowedTimelineFor:username since:date startingAtPage:pageNum count:0]; // zero means default
}


- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = @"statuses/home_timeline.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/home_timeline/%@.xml", username];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getFollowedTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = @"statuses/home_timeline.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/home_timeline/%@.xml", username];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
	
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date count:(int)numUpdates
{
	// Included for backwards-compatibility.
    return [self getUserTimelineFor:username since:date startingAtPage:0 count:numUpdates];
}


- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)numUpdates
{
	NSString *path = @"statuses/user_timeline.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (numUpdates > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", numUpdates] forKey:@"count"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/user_timeline/%@.xml", username];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)numUpdates
{
	NSString *path = @"statuses/user_timeline.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (numUpdates > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", numUpdates] forKey:@"count"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/user_timeline/%@.xml", username];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum
{
    NSString *path = @"account/archive.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getPublicTimelineSinceID:(NSString *)updateID
{
    NSString *path = @"statuses/public_timeline.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

- (NSString *)getRepliesStartingAtPage:(int)pageNum
{
    NSString *path = @"statuses/mentions.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterRepliesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum
{
    NSString *path = @"favorites.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"favorites/%@.xml", username];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUpdate:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/show/%@.xml", updateID];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatus];
}


#pragma mark Retrieving direct messages


- (NSString *)getDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum
{
    NSString *path = @"direct_messages.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


- (NSString *)getDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum
{
    NSString *path = @"direct_messages.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


- (NSString *)getSentDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum
{
    NSString *path = @"direct_messages/sent.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


- (NSString *)getSentDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum
{
    NSString *path = @"direct_messages/sent.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


#pragma mark Retrieving user information


- (NSString *)getUserInformationFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"users/show/%@.xml", username];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getUserInformationForEmail:(NSString *)email
{
    NSString *path = @"users/show.xml";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (email) {
        [params setObject:email forKey:@"email"];
    } else {
        return nil;
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum
{
    NSString *path = @"statuses/friends.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends/%@.xml", username];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}

- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtCursor:(long long)cursorNum
{
    NSString *path = @"statuses/friends.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends/%@.xml", username];
    }
    if (cursorNum >= -1) {
        [params setObject:[NSString stringWithFormat:@"%lld", cursorNum] forKey:@"cursor"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag
{
    NSString *path = @"statuses/followers.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (!flag) {
        [params setObject:@"true" forKey:@"lite"]; // slightly bizarre, but correct.
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


- (NSString *)getFeaturedUsers
{
    NSString *path = @"statuses/featured.xml";
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


#pragma mark Sending and editing updates


- (NSString *)sendUpdate:(NSString *)status
{
    return [self sendUpdate:status inReplyTo:0];
}


- (NSString *)sendUpdate:(NSString *)status inReplyTo:(NSString *)updateID
{
    if (!status) {
        return nil;
    }
    
    NSString *path = @"statuses/update.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:status forKey:@"status"];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"in_reply_to_status_id"];
    }
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:nil body:body 
                            requestType:MGTwitterStatusSend 
                           responseType:MGTwitterStatus];
}


- (NSString *)deleteUpdate:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/destroy/%@.xml", updateID];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}


- (NSString *)markUpdate:(NSString *)updateID asFavorite:(BOOL)flag
{
    NSString *path = [NSString stringWithFormat:@"favorites/%@/%@.xml", 
                      (flag) ? @"create" : @"destroy" ,
                      updateID];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterStatus];
}

- (NSString *)retweetUpdate:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/retweet/%@.xml", updateID];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterStatus];	
}

#pragma mark Sending and editing direct messages


- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username
{
    if (!message || !username) {
        return nil;
    }
    
    NSString *path = @"direct_messages/new.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:message forKey:@"text"];
    [params setObject:username forKey:@"user"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:nil body:body 
                            requestType:MGTwitterDirectMessageSend 
                           responseType:MGTwitterDirectMessage];
}


- (NSString *)deleteDirectMessage:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/destroy/%@.xml", updateID];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}

#pragma mark Adium Additions/Changes

#define MAX_NAME_LENGTH			20
#define MAX_EMAIL_LENGTH		40
#define MAX_URL_LENGTH			100
#define MAX_DESCRIPTION_LENGTH	160

- (NSString *)checkUserCredentials
{
    NSString *path = @"account/verify_credentials.xml";
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getRepliesSinceID:(NSString *)updateID startingAtPage:(int)pageNum
{
	NSString *path = @"statuses/mentions.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterRepliesRequest 
                           responseType:MGTwitterStatuses];
}

- (NSString *)updateProfileName:(NSString *)name
						  email:(NSString *)email
							url:(NSString *)url
					   location:(NSString *)location
					description:(NSString *)description
{
	if (!name && !email && !url && !location && !description) {
        return nil;
    }
    
    NSString *path = @"account/update_profile.xml";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	
	if (name) {
		if(name.length > MAX_NAME_LENGTH) {
			name = [name substringToIndex:MAX_NAME_LENGTH];
		}
		
		[params setObject:name forKey:@"name"];
	}

	if (email) {
		if(email.length > MAX_EMAIL_LENGTH) {
			email = [email substringToIndex:MAX_EMAIL_LENGTH];
		}
		
		[params setObject:email forKey:@"email"];
	}
	
	if (url) {
		if(url.length > MAX_URL_LENGTH) {
			url = [url substringToIndex:MAX_URL_LENGTH];
		}
		
		[params setObject:url forKey:@"url"];
	}
	
	if (location) {
		if(location.length > MAX_LOCATION_LENGTH) {
			location = [location substringToIndex:MAX_LOCATION_LENGTH];
		}
		
		[params setObject:location forKey:@"location"];
	}
	
	if (description) {
		if(description.length > MAX_DESCRIPTION_LENGTH) {
			description = [description substringToIndex:MAX_DESCRIPTION_LENGTH];
		}
		
		[params setObject:description forKey:@"description"];
	}

    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:nil body:body 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}

- (NSString *)updateProfileImage:(NSData *)profileImage
{
	if (!profileImage || _useOAuth) {
        return nil;
    }
    
    NSString *path = @"account/update_profile_image.xml";
	
	NSMutableData *body = [NSMutableData data];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	
	NSImage *image = [[NSImage alloc] initWithData:profileImage];
	
	NSBitmapImageRep *bitmapImageRep = nil;
	for(NSImageRep *imageRep in image.representations) {
		if([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			bitmapImageRep = (NSBitmapImageRep *)imageRep;
		}
	}
	
	if(!bitmapImageRep) {
		return nil;
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"image\"; filename=\"adium_icon.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[bitmapImageRep representationUsingType:NSPNGFileType properties:nil]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

    return [self _sendRequestWithMethod:HTTP_MULTIPART_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}

#pragma mark Adium OAuth Changes

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(id)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{
    // Construct appropriate URL string.
    NSString *fullPath = path;
    if (params) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }

	NSString *urlString = nil;
	
	if (!_useOAuth) {
		#if SET_AUTHORIZATION_IN_HEADER
			urlString = [NSString stringWithFormat:@"%@://%@/%@", 
						 (_secureConnection) ? @"https" : @"http",
						 _APIDomain, fullPath];
		#else 
			urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@", 
						 (_secureConnection) ? @"https" : @"http", 
						 [self _encodeString:_username], [self _encodeString:_password], 
						 _APIDomain, fullPath];
		#endif
	} else {
		urlString = [NSString stringWithFormat:@"%@://%@/%@", 
					 (_secureConnection) ? @"https" : @"http",
					 _APIDomain, fullPath];		
	}
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
	
	NSMutableURLRequest *theRequest = nil;
	
	if (_useOAuth) {
		if (!_consumer || !_accessToken) {
			NSLog(@"No consumer or access token, fail.");
			return nil;
		}
		
		theRequest = [[OAMutableURLRequest alloc] initWithURL:finalURL
													  consumer:_consumer
														 token:_accessToken
														 realm:nil
											 signatureProvider:nil];
	} else {
		// Construct an NSMutableURLRequest for the URL and set appropriate request method.
		theRequest = [NSMutableURLRequest requestWithURL:finalURL 
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:URL_REQUEST_TIMEOUT];
	}
		
	if(method && [method isEqualToString:HTTP_MULTIPART_METHOD]) {
		method = HTTP_POST_METHOD;
		[theRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIPART_FORM_BOUNDARY] forHTTPHeaderField:@"Content-type"];
	}
	
    if (method) {
        [theRequest setHTTPMethod:method];
    }
	
    [theRequest setHTTPShouldHandleCookies:NO];
	
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
    
#if SET_AUTHORIZATION_IN_HEADER
	if (_useOAuth && [self username] && [self password]) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [self username], [self password]];
		NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	}
#endif
	
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
	
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
		if([body isKindOfClass:[NSString class]]) {
			NSString *finalBody = @"";
			if (body) {
				finalBody = [finalBody stringByAppendingString:body];
			}
			if (_clientSourceToken) {
				finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
																(body) ? @"&" : @"?" , 
																_clientSourceToken]];
			}
			
			if (finalBody) {
				[theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
			}
		} else if ([body isKindOfClass:[NSData class]]) {
			[theRequest setHTTPBody:body];
		}
    }
	
	if (_useOAuth) {
		[(OAMutableURLRequest *)theRequest prepare];
    }
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
    }
    
    return [connection identifier];
}

@synthesize consumer = _consumer, accessToken = _accessToken, useOAuth = _useOAuth;

@end
