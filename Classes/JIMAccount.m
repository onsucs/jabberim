//
//  JIMAccount.m
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAccount.h"

NSString* const JIMAccountDidConnectNotification = @"JIMAccountDidConnectNotification";
NSString* const JIMAccountDidFailToConnectNotification = @"JIMAccountDidFailToConnectNotification";
NSString* const JIMAccountDidFailToRegisterNotification = @"JIMAccountDidFailToRegisterNotification";
NSString* const JIMAccountDidRefreshListOfChatroomsNotification = @"JIMAccountDidRefreshListOfChatroomsNotification";
NSString* const JIMAccountDidChangeStatusNotification = @"JIMAccountDidChangeStatusNotification";

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
		
		services = [[NSMutableArray alloc] init];
		chatrooms = [[NSMutableArray alloc] init];
		
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
	
	[services release];
	[chatrooms release];
	[accountDict release];
	
	[super dealloc];
}

#pragma mark Settings
- (void)setAutoLogin:(NSInteger)autoLogin
{
	if(autoLogin == NSOnState)
	{
		[xmppService setAutoLogin:YES];
		[xmppService connect];
	}
	else
	{
		[xmppService setAutoLogin:NO];
		[self goOffline];
	}

	[accountDict setObject:[NSNumber numberWithInt:autoLogin] forKey:@"AutoLogin"];
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidChangeStatusNotification object:self];
}

- (void)goOffline
{
	[xmppService disconnect];
	show = XMPPPresenceShowUnknown;
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidChangeStatusNotification object:self];
}

#pragma mark Transports and Features

- (NSArray *)services
{
	return services;
}

- (JIMService *)serviceForFeature:(NSString *)feature
{
	for(JIMService *oneService in services)
		if([oneService hasFeatureWithName:feature])
		{
			NSLog(@"Has feature");
			return oneService;
		}
	
	return nil;
}

- (NSArray *)servicesWithFeature:(NSString *)feature
{
	NSMutableArray *servicesToReturn = [NSMutableArray array];
	
	for(JIMService *oneService in services)
		if([oneService hasFeatureWithName:feature])
			[servicesToReturn addObject:oneService];
	
	return servicesToReturn;
}

#pragma mark Multi-User Chat
- (NSArray *)chatrooms
{
	return [chatrooms sortedArrayUsingSelector:@selector(compareByName:)];
}

- (NSArray *)chatroomForName:(NSString *)name
{
	return nil;
}

- (void)refreshChatrooms
{
	XMPPDiscoItemsInfoQuery *itemsQuery = [[XMPPDiscoItemsInfoQuery alloc] initWithType:XMPPIQTypeGet to:nil service:xmppService];
	[itemsQuery.stanza addAttributeWithName:@"to" stringValue:[[[self serviceForFeature:@"http://jabber.org/protocol/muc"] jid] domain]];
	[itemsQuery setDelegate:self];
	[itemsQuery send];
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidChangeStatusNotification object:self];
	
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
		
		if([itemsQuery.jid isEqual:[[self serviceForFeature:@"http://jabber.org/protocol/muc"] jid]]) //Chatrooms
		{
			[chatrooms removeAllObjects];
			
			for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
				[chatrooms addObject:oneElement];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidRefreshListOfChatroomsNotification object:self];
		}
		else //Services
		{
			for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
			{
				JIMService *oneService = [[JIMService alloc] initWithDiscoItemsItem:oneElement service:xmppService];
				[services addObject:oneService];
				[oneService release];
			}
		}
	}
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	//FIXME: Implement
	
	[[note object] release];
}

#pragma mark Comparison Methods
- (NSComparisonResult)compareByNameAndEnabled:(JIMAccount *)another
{
	if([[self.accountDict objectForKey:@"AutoLogin"] intValue] == NSOnState)
	{
		if([[another.accountDict objectForKey:@"AutoLogin"] intValue] == NSOnState)
			return [[self.xmppService.myJID fullString] compare:[another.xmppService.myJID fullString]];
		else
			return NSOrderedAscending;
	}
	else
	{
		if([[another.accountDict objectForKey:@"AutoLogin"] intValue] == NSOnState)
			return NSOrderedDescending;
		else
			return [[self.xmppService.myJID fullString] compare:[another.xmppService.myJID fullString]];
	}
}

@end
