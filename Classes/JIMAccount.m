//
//  JIMAccount.m
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAccount.h"
#import "XMPP.h"

NSString* const JIMAccountDidFailToConnectNotification = @"JIMAccountDidFailToConnectNotification";
NSString* const JIMAccountDidConnectNotification = @"JIMAccountDidConnectNotification";

@implementation JIMAccount

@synthesize xmppService;
@synthesize accountDict;
@synthesize error;

- (id)initWithAccountDict:(NSDictionary *)newAccountDict
{
	if((self = [super init]))
	{
		accountDict = newAccountDict;
		[accountDict retain];
		
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
		
		[xmppService setAutoLogin:[[accountDict objectForKey:@"AutoLogin"] boolValue]];
		[xmppService setAutoRoster:YES];
		[xmppService setAutoPresence:YES];
		
		if(![xmppService isConnected])
			[xmppService connect];
		
		/*NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(rosterDidAddUsers:) name:XMPPRosterDidAddUsersNotification object:[xmppService roster]];
		[nc addObserver:self selector:@selector(rosterDidRemoveUsers:) name:XMPPRosterDidRemoveUsersNotification object:[xmppService roster]];*/
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[xmppService goOffline];
	[xmppService disconnect];
	[xmppService release];
	[accountDict release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPService Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)serviceDidBeginConnect:(NSNotification *)note
{
}

- (void)serviceDidConnect:(NSNotification *)note
{
	//[xmppService authenticateUser];
	//[statusButton selectItemWithTitle:@"Available"];
}

- (void)serviceDidFailConnect:(NSNotification *)note
{
	NSLog(@"---------- xmppServiceDidNotConnect ----------");
	/*if([sender streamError])
	 {
	 NSLog(@"           error: %@", [sender streamError]);
	 }*/
	
	self.error = @"Unable to establish connection";
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidFailToConnectNotification object:self];
	
	/*
	 // Update tracking variables
	 isRegistering = NO;
	 isAuthenticating = NO;
	 
	 // Update GUI
	 [signInButton setEnabled:YES];
	 [registerButton setEnabled:YES];
	 [messageField setStringValue:@"Cannot connect to server"];*/
}

- (void)serviceDidDisconnect:(NSNotification *)note
{
	NSLog(@"---------- xmppServiceDidDisconnect ----------");
	/*if ([sender streamError])
	 {
	 NSLog(@"           error: %@", [sender streamError]);
	 }*/
	
	[NSApp stopModal];
}

- (void)serviceDidRegister:(NSNotification *)note
{
	/*
	 // Update tracking variables
	 isRegistering = NO;
	 
	 // Update GUI
	 [signInButton setEnabled:YES];
	 [registerButton setEnabled:YES];
	 [messageField setStringValue:@"Registered new user"];
	 */
}

- (void)serviceDidFailRegister:(NSNotification *)note
{
	/*
	 NSLog(@"---------- serviceDidNotConnect ----------");
	 if([note error])
	 {
	 NSLog(@"           error: %@", [note error]);
	 }
	 
	 // Update tracking variables
	 isRegistering = NO;
	 
	 // Update GUI
	 [signInButton setEnabled:YES];
	 [registerButton setEnabled:YES];
	 [messageField setStringValue:@"Username is taken"];*/
}

- (void)serviceDidAuthenticate:(NSNotification *)note
{
	self.error = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidConnectNotification object:self];
	
	/*
	 // Update tracking variables
	 isAuthenticating = NO;
	 
	 // Close the sheet
	 [signInSheet orderOut:self];
	 [NSApp endSheet:signInSheet];*/
}

- (void)serviceDidFailAuthenticate:(NSNotification *)note
{
	NSLog(@"---------- serviceDidFailAuthenticate ----------");
	if([note error])
	{
		NSLog(@"           error: %@", [note error]);
	}
	
	self.error = @"Username or password wrong";
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountDidFailToConnectNotification object:self];
	
	/*
	 // Update tracking variables
	 isAuthenticating = NO;
	 
	 // Update GUI
	 [signInButton setEnabled:YES];
	 [registerButton setEnabled:YES];
	 [messageField setStringValue:@"Invalid username/password"];*/
}

@end
