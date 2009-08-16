#import "XMPPService.h"
#import "XMPPStream.h"
#import "XMPPJID.h"
#import "XMPPResource.h"
#import "XMPPError.h"
#import "NSNotificationCenter+RNDelegate.h"
#import "XMPPInfoQuery.h"
#import "XMPPIQStanza.h"
#import "XMPPCapabilityManager.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
NSString* const XMPPServiceDidBeginConnectNotification = @"XMPPServiceDidBeginConnectNotification";
NSString* const XMPPServiceDidConnectNotification = @"XMPPServiceDidConnectNotification";
NSString* const XMPPServiceDidFailConnectNotification = @"XMPPServiceDidFailConnectNotification";
NSString* const XMPPServiceDidDisconnectNotification = @"XMPPServiceDidDisconnectNotification";
NSString* const XMPPServiceDidRegisterNotification = @"XMPPServiceDidRegisterNotification";
NSString* const XMPPServiceDidFailRegisterNotification = @"XMPPServiceDidFailRegisterNotification";
NSString* const XMPPServiceDidAuthenticateNotification = @"XMPPServiceDidAuthenticateNotification";
NSString* const XMPPServiceDidFailAuthenticateNotification = @"XMPPServiceDidFailAuthenticateNotification";
NSString* const XMPPServiceDidReceiveTCPErrorNotification = @"XMPPServiceDidReceiveTCPErrorNotification";
NSString* const XMPPServiceDidSendStanzaNotification = @"XMPPServiceDidSendStanzaNotification";
NSString* const XMPPServiceDidFailSendStanzaNotification = @"XMPPServiceDidFailSendStanzaNotification";
NSString* const XMPPServiceDidReceiveMessageStanzaNotification = @"XMPPServiceDidReceiveMessageStanzaNotification";
NSString* const XMPPServiceDidReceivePresenceStanzaNotification = @"XMPPServiceDidReceivePresenceStanzaNotification";
NSString* const XMPPServiceDidReceiveIQStanzaNotification = @"XMPPServiceDidReceiveIQStanzaNotification";

enum XMPPServiceFlags
{
	kUsesOldStyleSSL      = 1 << 0,  // If set, TLS is established prior to any communication (no StartTLS)
	kAutoLogin            = 1 << 1,  // If set, client automatically attempts login after connection is established
	kAllowsPlaintextAuth  = 1 << 2,  // If set, client allows plaintext authentication
	kAutoRoster           = 1 << 3,  // If set, client automatically request roster after authentication
	kAutoPresence         = 1 << 4,  // If set, client automatically becaomes available after authentication
	kAutoReconnect        = 1 << 5,  // If set, client automatically attempts to reconnect after a disconnection
	kShouldReconnect      = 1 << 6,  // If set, disconnection was accidental, and autoReconnect may be used
	kHasRoster            = 1 << 7,  // If set, client has received the roster
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface XMPPService ()
@property (nonatomic, readwrite, retain)	XMPPStream *stream;
@property (nonatomic, readwrite, copy)		NSString *domain;
@property (nonatomic, readwrite, assign)	UInt16 port;
@property (nonatomic, readwrite, retain)	XMPPResource *myResource;
@property (nonatomic, readwrite, copy)		NSString *password;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPService
@synthesize stream = _stream;
@synthesize serviceIcon = _serviceIcon;
@synthesize domain = _domain;
@synthesize port = _port;
@synthesize password = _password;
@synthesize priority = _priority;
@synthesize myResource = _myResource;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSSet *)notificationNames
{
	static NSSet *notificationNames = nil;
	if (notificationNames == nil)
	{
		notificationNames = [[NSSet alloc] initWithObjects:
							 XMPPServiceDidBeginConnectNotification,
							 XMPPServiceDidConnectNotification,
							 XMPPServiceDidFailConnectNotification,
							 XMPPServiceDidDisconnectNotification,
							 XMPPServiceDidRegisterNotification,
							 XMPPServiceDidFailRegisterNotification,
							 XMPPServiceDidAuthenticateNotification,
							 XMPPServiceDidFailAuthenticateNotification,
							 XMPPServiceDidReceiveTCPErrorNotification,
							 XMPPServiceDidSendStanzaNotification,
							 XMPPServiceDidFailSendStanzaNotification,
							 XMPPServiceDidReceiveMessageStanzaNotification,
							 XMPPServiceDidReceivePresenceStanzaNotification,
							 XMPPServiceDidReceiveIQStanzaNotification,
							 nil];
	}
	return notificationNames;
}		

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithDomain:(NSString *)domain port:(UInt16)port jid:(XMPPJID *)jid password:(NSString *)password
{
	if ((self = [super init]))
	{
		self.domain = domain;
		self.port = port;
		self.myResource = [[[XMPPResource alloc] initWithJID:jid] autorelease];
		self.password = password;

		self.priority = 1;

		self.autoLogin = YES;
		self.allowsPlaintextAuth = YES;
		self.autoReconnect = YES;

		self.stream = [[[XMPPStream alloc] initWithDelegate:self] autorelease];
		
		_serviceIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Jabber Icon" ofType:@"png"]];
		
		// Features (make sure these are core features, not chat features)
		XMPPCapabilityManager *cm = [XMPPCapabilityManager sharedManager];
		[cm addService:self];
		[cm addFeature:@"urn:xmpp:delay"];	// XEP-0203 Delayed Delivery
	}
	return self;
}

- (void) dealloc
{
	[_stream release]; _stream = nil;
	[_domain release]; _domain = nil;
	[_password release]; _password = nil;
	[_myResource release]; _myResource = nil;
	[_pendingStanzas release]; _pendingStanzas = nil;
	[_serviceIcon release]; _serviceIcon = nil;
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)uniqueIdentifier
{
	// FIXME: There are some assumptions here that should be thought about.
	// This requires that you not log into the same account+domain as two different resources.
	// We can't encode resource here because it can change. Port's a little funny because "0" isn't unique.
	return [NSString stringWithFormat:@"%@:%d:%@", self.domain, self.port, self.myResource];
}

- (void)addObserverForRespondingNotifications:(id)object
{
	[[NSNotificationCenter defaultCenter] addObserver:object forRespondingNotificationNames:[[self class] notificationNames] prefix:@"XMPP" object:self];
}
		
- (NSMutableDictionary *)pendingStanzas
{
	if (_pendingStanzas == nil)
	{
		_pendingStanzas = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return _pendingStanzas;
}

- (BOOL)validatesCertificateChain
{
	return [[self stream] validatesCertificateChain];
}

- (void)setValidatesCertificateChain:(BOOL)flag
{
	[[self stream] setValidatesCertificateChain:flag];
}

- (BOOL)allowsSelfSignedCertificates
{
	return [[self stream] allowsSelfSignedCertificates];
}

- (void)setAllowsSelfSignedCertificates:(BOOL)flag
{
	[[self stream] setAllowsSelfSignedCertificates:flag];
}

- (BOOL)allowsSSLHostNameMismatch
{
	return [[self stream] allowsSSLHostNameMismatch];
}

- (void)setAllowsSSLHostNameMismatch:(BOOL)flag
{
	[[self stream] setAllowsSSLHostNameMismatch:flag];
}

- (BOOL)isDisconnected
{
	return [[self stream] isDisconnected];
}

- (BOOL)isConnected
{
	return [[self stream] isConnected];
}

- (BOOL)isSecure
{
	return [[self stream] isSecure];
}

- (BOOL)isAuthenticated
{
	return [[self stream] isAuthenticated];
}

- (BOOL)supportsPlainAuthentication
{
	return [[self stream] supportsPlainAuthentication];
}

- (BOOL)supportsDigestMD5Authentication
{
	return [[self stream] supportsDigestMD5Authentication];
}

- (BOOL)supportsInBandRegistration
{
	return [[self stream] supportsInBandRegistration];
}

- (BOOL)autoLogin
{
	return _serviceFlags.autoLogin;
}

- (void)setAutoLogin:(BOOL)flag
{
	_serviceFlags.autoLogin = flag;
}

- (BOOL)autoRoster
{
	return _serviceFlags.autoRoster;
}

- (void)setAutoRoster:(BOOL)flag
{
	_serviceFlags.autoRoster = flag;
}

- (BOOL)autoPresence
{
	return _serviceFlags.autoPresence;
}

- (void)setAutoPresence:(BOOL)flag
{
	_serviceFlags.autoPresence = flag;
}

- (BOOL)autoReconnect
{
	return _serviceFlags.autoReconnect;
}

- (void)setAutoReconnect:(BOOL)flag
{
	_serviceFlags.autoReconnect = flag;
}

- (BOOL)usesOldStyleSSL
{
	return _serviceFlags.usesOldStyleSSL;
}
			
- (void)setUsesOldStyleSSL:(BOOL)flag
{
	_serviceFlags.usesOldStyleSSL = flag;
}

- (BOOL)allowsPlaintextAuth
{
	return _serviceFlags.allowsPlaintextAuth;
}

- (void)setAllowsPlaintextAuth:(BOOL)flag
{
	_serviceFlags.allowsPlaintextAuth = flag;
}

- (BOOL)shouldReconnect
{
	return _serviceFlags.shouldReconnect;
}

- (void)setShouldReconnect:(BOOL)flag
{
	_serviceFlags.shouldReconnect = flag;
}

- (XMPPJID *)myJID
{
	return self.myResource.jid;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connect
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidBeginConnectNotification object:self];
	if ([self usesOldStyleSSL])
	{
		[self.stream connectToSecureHost:self.domain onPort:self.port withVirtualHost:self.myJID.domain];
	}
	else
	{
		[self.stream connectToHost:self.domain onPort:self.port withVirtualHost:self.myJID.domain];
	}
}

- (void)registerUser
{
	[self.stream registerUser:self.myJID.user withPassword:self.password];
}

- (void)authenticateUser
{
	XMPPStream *stream = [self stream];
	BOOL secureAuth = NO;
	
	if([stream supportsDigestMD5Authentication])
	{
		secureAuth = YES;
	}
	else if([stream supportsPlainAuthentication])
	{
		secureAuth = [[self stream] isSecure];
	}
	else if([stream supportsDeprecatedDigestAuthentication])
	{
		secureAuth = YES;
	}
	else
	{
		secureAuth = [stream isSecure];
	}
	
	if(secureAuth || [self allowsPlaintextAuth])
	{
		[stream authenticateUser:self.myJID.user withPassword:self.password resource:self.myJID.resource];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidFailAuthenticateNotification 
															object:self
													   errorDomain:XMPPErrorDomain
														 errorCode:XMPPErrorSASLMechanismTooWeak
												  errorDescription:NSLocalizedString(@"Cannot authenticate securely as required.",
																					 @"Secure authentication is required, but not available")];
	}
}

- (void)goOnline
{
	NSString *priorityStr = [NSString stringWithFormat:@"%i", [self priority]];
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:priorityStr]];
	
	[[self stream] sendElement:presence];
}

- (void)goOffline
{
	// Send offline presence element
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addAttributeWithName:@"type" stringValue:@"unavailable"];
	
	[[self stream] sendElement:presence];
}

- (void)disconnect
{
	// Turn off the shouldReconnect flag.
	// This flag will tell us that we should not automatically attempt to reconnect when the connection closes.
	[self setShouldReconnect:NO];
	
	[[self stream] disconnect];
}

- (void)setShow:(NSString *)show andStatus:(NSString *)status
{	
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	if(show)
		[presence addChild:[NSXMLElement elementWithName:@"show" stringValue:show]];
	if(status)
		[presence addChild:[NSXMLElement elementWithName:@"status" stringValue:status]];
	[presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:[NSString stringWithFormat:@"%i", self.priority]]];
	
	[[self stream] sendElement:presence];
}

- (void)sendStanza:(XMPPStanza *)stanza
{
	long stanzaIDHash = [[stanza uniqueIdentifier] hash];
	if (stanzaIDHash != 0)
	{
		[[self stream] sendElement:stanza andNotifyMe:stanzaIDHash];
		[[self pendingStanzas] setObject:stanza forKey:[NSNumber numberWithLong:stanzaIDHash]];
	}
	else
	{
		[[self stream] sendElement:stanza];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reconnecting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is invoked a few seconds after a disconnection from the server,
 * or after we receive notification that we may once again have a working internet connection.
 * If we are still disconnected, it will attempt to reconnect if the network connection appears to be online.
 **/
- (void)attemptReconnect:(id)ignore
{
	NSLog(@"XMPPClient: attemptReconnect method called...");
	
	if([self isDisconnected] && [self autoReconnect] && [self shouldReconnect])
	{
#if TARGET_OS_IPHONE || MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
		// FIXME: Monitor network reachability rather than polling
		[self connect];
#else
		SCNetworkConnectionFlags reachabilityStatus;
		BOOL success = SCNetworkCheckReachabilityByName("www.deusty.com", &reachabilityStatus);
		
		if(success && (reachabilityStatus & kSCNetworkFlagsReachable))
		{
			[self connect];
		}
#endif
	}
}

///////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream delegate methods
///////////////////////////////////////////////////////////////////////////
- (void)xmppStreamDidOpen:(XMPPStream *)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidConnectNotification object:self];
	
	if([self autoLogin])
	{
		[self authenticateUser];
	}
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidRegisterNotification object:self];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidFailRegisterNotification object:self error:[NSError errorWithXMPPXMLElement:error]];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	// We're now connected and properly authenticated
	// Should we get accidentally disconnected we should automatically reconnect (if kAutoReconnect is set)
	[self setShouldReconnect:YES];
	
	// We may have authenticated with something different than we asked for
	self.myResource.jid = [XMPPJID jidWithUser:[[self stream] authenticatedUsername] domain:self.myResource.jid.domain resource:[self.stream authenticatedResource]];

	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidAuthenticateNotification object:self];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidFailAuthenticateNotification object:self error:[NSError errorWithXMPPXMLElement:error]];
}

- (void)xmppStream:(XMPPStream *)sender didSendElementWithTag:(long)tag
{
	NSNumber *hash = [NSNumber numberWithLong:tag];
	XMPPStanza *stanza = [[self pendingStanzas] objectForKey:hash];
	if (stanza != nil)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidSendStanzaNotification object:self stanza:stanza];
		[[self pendingStanzas] removeObjectForKey:hash];
	}
}

//
// Posting Notifications from Stream
// Do not post these are the current event loop. If the receivers of these messages do anything that 
// bump the RunLoop (such as using NSAttributedString -initWithHTML:), we will get very hard-to-track
// errors in AsyncSocket, which is sensitive to bumping the RunLoop (in the same way that NSURLConnection
// is, or just about any other run-loop based network reading algorithm is going to be). No one *should*
// bumping the RunLoop, but NSAttributeString does because it uses WebKit under the covers. Delaying the
// posting just protects us from any problems that look like that.
//
- (void)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQStanza *)iq
{
	//That's what we care about...
	if([iq type] == XMPPIQTypeGet)
	{
		if([iq elementForName:@"query" xmlns:@"jabber:iq:version"]) //Recieved request for general client information
		{
			NSXMLElement *name = [NSXMLElement elementWithName:@"name"];
			[name setStringValue:[NSString stringWithFormat:@"%@ (XMPP.framework)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
			NSXMLElement *version = [NSXMLElement elementWithName:@"version"];
			[version setStringValue:[NSString stringWithFormat:@"%@ (1.0 Enhanced)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
			NSXMLElement *os = [NSXMLElement elementWithName:@"os"];
			[os setStringValue:[NSString stringWithFormat:@"Mac OS X %@", [[NSProcessInfo processInfo] operatingSystemVersionString]]];
			
			NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:version"];
			[query addChild:name];
			[query addChild:version];
			if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"SendOS"] boolValue])
				[query addChild:os];
			
			XMPPInfoQuery *resultIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeResult
																	   to:[iq fromJID]
																  service:self];
			resultIQ.stanza.uniqueIdentifier = iq.uniqueIdentifier;
			[resultIQ.stanza addChild:query];
			[resultIQ send];
			[resultIQ release];
		}
		else if([iq elementForName:@"query" xmlns:@"jabber:iq:last"]) //Recieved request for last activity
		{
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"SendIdleTime"] boolValue])
			{
				NSXMLElement *forbidden = [NSXMLElement elementWithName:@"forbidden" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"];
				
				NSXMLElement *error = [NSXMLElement elementWithName:@"error"];
				[error addAttributeWithName:@"type" stringValue:@"auth"];
				[error addChild:forbidden];
				
				XMPPInfoQuery *resultIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeResult
																		   to:[iq fromJID]
																	  service:self];
				resultIQ.stanza.uniqueIdentifier = iq.uniqueIdentifier;
				[resultIQ.stanza addChild:error];
				[resultIQ send];
				[resultIQ release];
			}
			else
			{
				CFTimeInterval idleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStatePrivate, kCGAnyInputEventType);
				//On MDD Powermacs, the above function will return a large value when the machine is active (-1?).
				//Here we check for that value and correctly return a 0 idle time.
				if(idleTime >= 18446744000.0) idleTime = 0.0;
				
				NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:last"];
				[query addAttributeWithName:@"seconds" stringValue:[NSString stringWithFormat:@"%d", idleTime]];
				
				XMPPInfoQuery *resultIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeResult
																		   to:[iq fromJID]
																	  service:self];
				resultIQ.stanza.uniqueIdentifier = iq.uniqueIdentifier;
				[resultIQ.stanza addChild:query];
				[resultIQ send];
				[resultIQ release];
			}
		}
		else if([iq elementForName:@"time" xmlns:@"urn:xmpp:time"]) //Recieved request for client time
		{
			NSXMLElement *notImplemented = [NSXMLElement elementWithName:@"feature-not-implemented" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"];
			
			NSXMLElement *error = [NSXMLElement elementWithName:@"error"];
			[error addAttributeWithName:@"type" stringValue:@"cancle"];
			[error addChild:notImplemented];
			
			XMPPInfoQuery *errorIQ = [[XMPPInfoQuery alloc] initWithIQStanza:iq service:self];
			errorIQ.stanza.toJID = errorIQ.stanza.fromJID;
			errorIQ.stanza.fromJID = self.myJID;
			errorIQ.type = XMPPIQTypeError;
			[errorIQ.stanza addChild:error];
			[errorIQ send];
			[errorIQ release];
		}
	}
	else
	{
		//That's what others care about
		//NSLog(@"xmppService: didReceiveIQ:\n%@", [iq stringValue]);
		[[NSNotificationQueue defaultQueue] enqueueNotificationName:XMPPServiceDidReceiveIQStanzaNotification object:self stanza:iq];
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessageStanza *)message
{
	//NSLog(@"xmppService: didReceiveMessage:\n%@", [message stringValue]);
	[[NSNotificationQueue defaultQueue] enqueueNotificationName:XMPPServiceDidReceiveMessageStanzaNotification object:self stanza:message];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresenceStanza *)presence
{
	//NSLog(@"xmppService: didReceivePresence:\n%@", [presence stringValue]);
	[[NSNotificationQueue defaultQueue] enqueueNotificationName:XMPPServiceDidReceivePresenceStanzaNotification object:self stanza:presence];
}

/**
 * There are two types of errors: TCP errors and XMPP errors.
 * If a TCP error is encountered (failure to connect, broken connection, etc) a standard NSError object is passed.
 * If an XMPP error is encountered (<stream:error> for example) an NSXMLElement object is passed.
 * 
 * Note that standard errors (<iq type='error'/> for example) are delivered normally,
 * via the other didReceive...: methods.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	NSLog(@"xmppStream:didReceiveError:%@", error);
	if([self isAuthenticated])
	{
		// We were fully connected to the XMPP server, but we've been disconnected for some reason.
		// We will wait for a few seconds or so, and then attempt to reconnect if possible
		[self performSelector:@selector(attemptReconnect:) withObject:nil afterDelay:4.0];
	}
	if (error != nil && [error isKindOfClass:[NSXMLElement class]])
	{
		error = [NSError errorWithXMPPXMLElement:(NSXMLElement *)error];
	}
	if (error == nil)
	{
		error = [NSNull null];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidReceiveTCPErrorNotification object:self error:error];
}

- (void)xmppStreamDidClose:(XMPPStream *)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPServiceDidDisconnectNotification object:self];
}

@end
		
