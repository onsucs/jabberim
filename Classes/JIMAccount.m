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
@synthesize delegate;

- (id)initWithAccountDict:(NSDictionary *)newAccountDict
{
	if((self = [super initWithWindowNibName:@"JIMAccount"]))
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
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(rosterDidAddUsers:) name:XMPPRosterDidAddUsersNotification object:[xmppService roster]];
		[nc addObserver:self selector:@selector(rosterDidRemoveUsers:) name:XMPPRosterDidRemoveUsersNotification object:[xmppService roster]];
		
		[self showWindow:self];
	}
	return self;
}

- (void)dealloc
{
	//End any sheets
	[NSApp endSheet:addContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:removeContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:authorizeContactWindow returnCode:NSCancelButton];
	
	[[self window] close];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[xmppService goOffline];
	[xmppService disconnect];
	[xmppService release];
	
	[buddies release];
	[accountDict release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[rosterTable setTarget:self];
	[rosterTable setDoubleAction:@selector(startChat:)];
	JIMCell *contactCell = [[[JIMCell alloc] init] autorelease];
	[[rosterTable tableColumnWithIdentifier:@"Name"] setDataCell:contactCell];
	
	[[self window] makeKeyAndOrderFront:self];
}

- (IBAction)setStatus:(id)sender
{
	if([[sender titleOfSelectedItem] isEqualToString:@"Offline"])
		[xmppService goOffline];
	else
	{
		if(![xmppService isAuthenticated])
			[xmppService authenticateUser];
		
		if([[sender titleOfSelectedItem] isEqualToString:@"Available"])
			[xmppService setShow:nil andStatus:nil];
		else if([[sender titleOfSelectedItem] isEqualToString:@"Away"])
			[xmppService setShow:@"away" andStatus:@"Away"];
		else if([[sender titleOfSelectedItem] isEqualToString:@"Chat"])
			[xmppService setShow:@"chat" andStatus:@"I want to chat"];
		else if([[sender titleOfSelectedItem] isEqualToString:@"Extended away"])
			[xmppService setShow:@"xa" andStatus:@"Extended away"];
		else if([[sender titleOfSelectedItem] isEqualToString:@"Do not Disturb"])
			[xmppService setShow:@"dnd" andStatus:@"Do not Disturb"];
	}
}

- (IBAction)segmentedToolsButton:(id)sender
{
	if([sender selectedSegment] == 0)
	{
		if(![[statusButton titleOfSelectedItem] isEqualToString:@"Offline"])
		{
			[NSApp beginSheet:addContactWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(addContactSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
			[NSApp runModalForWindow:addContactWindow];
			[NSApp endSheet:addContactWindow];
			[addContactWindow orderOut:self];
		}
		else
			NSBeep();
	}
	else if([sender selectedSegment] == 1)
	{
		[self startChat:self];
	}
	else if([sender selectedSegment] == 2)
	{}		
}

- (IBAction)mainMenuItemPressed:(id)sender
{
	if([sender tag] == 42)
	{
		if(![[statusButton titleOfSelectedItem] isEqualToString:@"Offline"])
		{
			[NSApp beginSheet:addContactWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(addContactSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
			[NSApp runModalForWindow:addContactWindow];
			[NSApp endSheet:addContactWindow];
			[addContactWindow orderOut:self];
		}
		else
			NSBeep();
	}
}

- (IBAction)removeContact:(id)sender
{
	if([rosterTable selectedRow] > -1)
	{
		[jidToRemove setStringValue:[[[buddies objectAtIndex:[rosterTable selectedRow]] jid] fullString]];
		[nicknameToRemove setStringValue:[[buddies objectAtIndex:[rosterTable selectedRow]] displayName]];
		[contactImageToRemove setImage:[[buddies objectAtIndex:[rosterTable selectedRow]] image]];
		
		[NSApp beginSheet:removeContactWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(removeContactSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
		[NSApp runModalForWindow:removeContactWindow];
		[NSApp endSheet:removeContactWindow];
		[removeContactWindow orderOut:self];
	}
	else
		NSBeep();
}

- (IBAction)showContactInfos:(id)sender
{
	if([rosterTable selectedRow] > -1)
		[contactInfoController setXmppUser:[buddies objectAtIndex:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)startChat:(id)sender
{
	if([rosterTable selectedRow] > -1)
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:[buddies objectAtIndex:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)okSheet:(id)sender
{
	[NSApp endSheet:addContactWindow returnCode:NSOKButton];
	[NSApp endSheet:removeContactWindow returnCode:NSOKButton];
	[NSApp endSheet:authorizeContactWindow returnCode:NSOKButton];
}

- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:addContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:removeContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:authorizeContactWindow returnCode:NSCancelButton];
}

- (void)sortBuddies
{
	// FIXME: Implement
}

- (NSMutableArray *)buddies
{
	if (buddies == nil)
	{
		buddies = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return buddies;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Roster Table Data Source:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [buddies count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	XMPPUser *user = [buddies objectAtIndex:rowIndex];
	
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		JIMCell *itemCell = [[rosterTable tableColumnWithIdentifier:@"Name"] dataCell];
		
		[itemCell setTitle:[user displayName]];
		
		if([user presenceStatus] && ![[user presenceStatus] isEqualToString:@""])
			[itemCell setSubtitle:[user presenceStatus]];
		else
			[itemCell setSubtitle:nil];
		
		[itemCell setImage:[user image]];
		
		if([user chatState] == XMPPChatStateComposing)
		{
			[itemCell setStatusImage:[NSImage imageNamed:@"typing"]];
		}
		else if([user isOnline] && [user presenceShow] != XMPPPresenceShowUnknown)
		{
			if([user presenceShow] == XMPPPresenceShowAvailable)
				[itemCell setStatusImage:[NSImage imageNamed:@"available"]];
			else if([user presenceShow] == XMPPPresenceShowChat)
				[itemCell setStatusImage:[NSImage imageNamed:@"available"]];
			else if([user presenceShow] == XMPPPresenceShowAway)
				[itemCell setStatusImage:[NSImage imageNamed:@"away"]];
			else if([user presenceShow] == XMPPPresenceShowExtendedAway)
				[itemCell setStatusImage:[NSImage imageNamed:@"away"]];
			else if([user presenceShow] == XMPPPresenceShowDoNotDisturb)
				[itemCell setStatusImage:[NSImage imageNamed:@"busy"]];
		}
		else
			[itemCell setStatusImage:[NSImage imageNamed:@"offline"]];
		
		[itemCell setEnabled:NO];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	XMPPUser *user = [buddies objectAtIndex:rowIndex];
	
	if([user isOnline])
		[cell setEnabled:YES];
	else
		[cell setEnabled:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([rosterTable selectedRow] == -1)
		[segmentedToolsButton setEnabled:NO forSegment:1];
	else
		[segmentedToolsButton setEnabled:YES forSegment:1];
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
	
	[statusButton selectItemWithTitle:@"Offline"];
	
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
	[statusButton selectItemWithTitle:@"Offline"];
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
	[statusButton selectItemWithTitle:@"Available"];
	
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
	
	[statusButton selectItemWithTitle:@"Offline"];
	
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

- (void)rosterDidAddUsers:(NSNotification *)note
{
	NSSet *addedUsers = [note users];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	for (XMPPUser *user in addedUsers)
	{
		[[self buddies] addObject:user];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:user];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeNameNotification object:user];
	}
	
	[self sortBuddies];
	[rosterTable reloadData];
	
	NSSound *newMessageSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Buddy Logging In.aiff" byReference:YES];
	[newMessageSound play];
	[newMessageSound release];
}

- (void)rosterDidRemoveUsers:(NSNotification *)note
{
	NSSet *removedUsers = [note users];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	for (XMPPUser *user in removedUsers)
	{
		[nc removeObserver:self name:nil object:user];
		[[self buddies] removeObject:user];
	}	
	[rosterTable reloadData];
	
	NSSound *newMessageSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Buddy Logging Out.aiff" byReference:YES];
	[newMessageSound play];
	[newMessageSound release];
}

- (void)userDidChange:(NSNotification *)note
{
	[self sortBuddies];
	[rosterTable reloadData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sheet Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		XMPPSubscriptionRequest *request = [[[XMPPSubscriptionRequest alloc] initWithToJID:[XMPPJID jidWithString:[newContactJIDField stringValue]] service:xmppService] autorelease];
		[request send];
	}
}

- (void)removeContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		XMPPUser *userForRemoval = [buddies objectAtIndex:[rosterTable selectedRow]];
		[userForRemoval unsubscribe];
		[userForRemoval deleteFromRoster];
	}
}

@end
