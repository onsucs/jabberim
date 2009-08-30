//
//  JIMAccount.m
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAccount.h"
#import "XMPP.h"

NSString* const JIMAccountDidConnectNotification = @"JIMAccountDidConnectNotification";
NSString* const JIMAccountDidFailToConnectNotification = @"JIMAccountDidFailToConnectNotification";
NSString* const JIMAccountDidFailToRegisterNotification = @"JIMAccountDidFailToRegisterNotification";

@implementation JIMAccount

@synthesize accountDict;
@synthesize error;
@synthesize xmppService;
@synthesize show;

#pragma mark Init and Dealloc
- (id)initWithAccountDict:(NSDictionary *)newAccountDict
{
	if((self = [super init]))
	{
		accountDict = [newAccountDict mutableCopy];
		[accountDict retain];
		
		transportDictArray = [[NSMutableArray alloc] init];
		
		XMPPJID *jid = [XMPPJID jidWithString:[accountDict objectForKey:@"JabberID"] resource:[accountDict objectForKey:@"Resource"]];
		
		xmppService = [[XMPPChatService alloc] initWithDomain:[accountDict objectForKey:@"Server"]
														 port:[[accountDict objectForKey:@"Port"] intValue]
														  jid:jid
													 password:[accountDict objectForKey:@"Password"]];
		[xmppService addObserverForRespondingNotifications:self];
		
		[xmppService setUsesOldStyleSSL:[[accountDict objectForKey:@"ForceOldSSL"] boolValue]];
		[xmppService setAllowsSelfSignedCertificates:[[accountDict objectForKey:@"SelfSignedCerts"] boolValue]];
		[xmppService setAllowsSSLHostNameMismatch:[[accountDict objectForKey:@"SSLHostMismatch"] boolValue]];
		[xmppService setPriority:[[accountDict objectForKey:@"Priority"] intValue]];
		
		if([[accountDict objectForKey:@"Register"] boolValue])
		{
			[xmppService setAutoLogin:NO];
			[xmppService setAutoRoster:YES];
			[xmppService setAutoPresence:YES];
			
			[xmppService connect];
		}
		else
		{
			[xmppService setAutoLogin:YES];
			[xmppService setAutoRoster:YES];
			[xmppService setAutoPresence:YES];
			
			if([[accountDict objectForKey:@"AutoLogin"] boolValue])
				[xmppService connect];
		}
		
		show = XMPPPresenceShowUnknown;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[xmppService goOffline];
	[xmppService disconnect];
	[xmppService release];
	[transportDictArray release];
	[accountDict release];
	
	[super dealloc];
}

#pragma mark Status
- (void)setShow:(XMPPPresenceShow)newShow andStatus:(NSString *)newStatus
{	
	
	if(newShow == XMPPPresenceShowAvailable)
	{
		if([xmppService isConnected])
			[xmppService goOnline];
		else
			[xmppService connect];
	}
	else
	{
		NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
		
		if(newShow == XMPPPresenceShowAway)
			[presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"away"]];
		else if(newShow == XMPPPresenceShowExtendedAway)
			[presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"xa"]];
		else if(newShow == XMPPPresenceShowChat)
			[presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"chat"]];
		else if(newShow == XMPPPresenceShowDoNotDisturb)
			[presence addChild:[NSXMLElement elementWithName:@"show" stringValue:@"dnd"]];
		
		if(newStatus)
			[presence addChild:[NSXMLElement elementWithName:@"status" stringValue:newStatus]];
		
		[presence addChild:[NSXMLElement elementWithName:@"priority" stringValue:[NSString stringWithFormat:@"%i", [xmppService priority]]]];
		
		[xmppService sendElement:presence];
	}
	
	show = newShow;
}

- (void)goOffline
{
	[xmppService disconnect];
	
	show = XMPPPresenceShowUnknown;
}

#pragma mark Transports and Features

- (NSArray *)transports
{
	NSMutableArray *mutableTransportsArray = [[NSMutableArray alloc] init];
	
	for(NSMutableDictionary *transportDict in transportDictArray)
		[mutableTransportsArray addObject:[transportDict objectForKey:@"Transport Item"]];
	
	NSArray *transportsArray = [NSArray arrayWithArray:mutableTransportsArray];
	[mutableTransportsArray release];
	return transportsArray;
}

- (NSArray *)featuresOfTransport:(XMPPDiscoItemsItemElement *)item
{
	for(NSMutableDictionary *transportDict in transportDictArray)
	{
		if([[transportDict objectForKey:@"Transport Item"] isEqual:item])
			return [transportDict objectForKey:@"Transport Features"];
	}
	
	return nil;
}

- (XMPPDiscoItemsItemElement *)transportForFeature:(NSString *)feature
{
	for(NSMutableDictionary *transportDict in transportDictArray)
	{
		if([(XMPPDiscoInfoInfoQuery *)[transportDict objectForKey:@"Transport Features"] hasFeatureWithName:feature])
			return [transportDict objectForKey:@"Transport Item"];
	}
	
	return nil;
}

- (BOOL)transport:(XMPPDiscoItemsItemElement *)item hasFeature:(NSString *)feature
{
	for(NSMutableDictionary *transportDict in transportDictArray)
	{
		if([[[transportDict objectForKey:@"Transport Item"] jid] isEqual:item.jid])
			return [(XMPPDiscoInfoInfoQuery *)[transportDict objectForKey:@"Transport Features"] hasFeatureWithName:feature];
	}
	
	return NO;
}

#pragma mark XMPPService Delegate Methods
- (void)serviceDidBeginConnect:(NSNotification *)note
{
}

- (void)serviceDidConnect:(NSNotification *)note
{
	if([[accountDict objectForKey:@"Register"] boolValue])
		[self.xmppService registerUser];
}

- (void)serviceDidFailConnect:(NSNotification *)note
{
	NSLog(@"---------- xmppServiceDidNotConnect ----------");
	if([note error])
	{
		NSLog(@"           error: %@", [note error]);
	}
	
	error = @"Unable to establish connection";
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidFailToConnectNotification object:self];
}

- (void)serviceDidDisconnect:(NSNotification *)note
{
	NSLog(@"---------- xmppServiceDidDisconnect ----------");
	if([note error])
	{
		NSLog(@"           error: %@", [note error]);
	}
	
	[NSApp stopModal];
}

- (void)serviceDidRegister:(NSNotification *)note
{
	[self.xmppService setAutoLogin:YES];
	[self.accountDict setObject:[NSNumber numberWithInt:NSOffState] forKey:@"Register"];
	
	if([[self.accountDict objectForKey:@"AutoLogin"] boolValue])
		[self.xmppService authenticateUser];
}

- (void)serviceDidFailRegister:(NSNotification *)note
{
	error = @"Unable to register account";
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidFailToRegisterNotification object:self];
	
	
	NSLog(@"---------- serviceDidNotConnect ----------");
	if([note error])
	{
		NSLog(@"           error: %@", [note error]);
	}
}

- (void)serviceDidAuthenticate:(NSNotification *)note
{
	error = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidConnectNotification object:self];
	
	if([xmppService autoPresence])
		show = XMPPPresenceShowAvailable;
	
	XMPPDiscoItemsInfoQuery *itemsQuery = [[XMPPDiscoItemsInfoQuery alloc] initWithType:XMPPIQTypeGet to:nil service:xmppService];
	[itemsQuery.stanza addAttributeWithName:@"to" stringValue:[accountDict objectForKey:@"Server"]];
	[itemsQuery setDelegate:self];
	[itemsQuery send];
}

- (void)serviceDidFailAuthenticate:(NSNotification *)note
{
	NSLog(@"---------- serviceDidFailAuthenticate ----------");
	if([note error])
	{
		NSLog(@"           error: %@", [note error]);
	}
	
	error = @"Username or password wrong";
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidFailToConnectNotification object:self];
}

#pragma mark XMPPInfoQuery Delegate Methods
- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	if([[note object] isKindOfClass:[XMPPDiscoItemsInfoQuery class]])
	{
		XMPPDiscoItemsInfoQuery *itemsQuery = [note object];
		
		for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
		{
			NSLog(@"JID String: %@", [oneElement.jid fullString]);
			
			[transportDictArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:oneElement, @"Transport Item", nil]];
			
			XMPPDiscoInfoInfoQuery *infoQuery = [[XMPPDiscoInfoInfoQuery alloc] initWithType:XMPPIQTypeGet to:oneElement.jid service:xmppService];
			[infoQuery setDelegate:self];
			[infoQuery send];
		}
	}
	else if([[note object] isKindOfClass:[XMPPDiscoInfoInfoQuery class]])
	{
		XMPPDiscoInfoInfoQuery *infoQuery = [note object];
		
		for(NSMutableDictionary *oneTransport in transportDictArray)
		{
			NSLog(@"Transport JID: %@, Query JID: %@", [[[oneTransport objectForKey:@"Transport Item"] jid] fullString], [infoQuery.jid fullString]);
			
			if([[[oneTransport objectForKey:@"Transport Item"] jid] isEqual:infoQuery.jid])
				[oneTransport setObject:infoQuery forKey:@"Transport Features"];
		}
	}
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	//FIXME: Implement
	
	[[note object] release];
}

@end
