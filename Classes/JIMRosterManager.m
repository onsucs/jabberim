//
//  JIMRosterManager.m
//  JabberIM
//
//  Created by Roland Moers on 16.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMRosterManager.h"

@implementation JIMRosterManager

- (id)init
{
	if((self = [super initWithWindowNibName:@"JIMRosterManager"]))
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(rosterDidAddUsers:) name:XMPPRosterDidAddUsersNotification object:nil];
		[nc addObserver:self selector:@selector(rosterDidRemoveUsers:) name:XMPPRosterDidRemoveUsersNotification object:nil];
		
		buddieGroups = [[NSMutableArray alloc] initWithObjects:@"Online", @"Offline", nil];
	}
	return self;
}

- (void)dealloc
{
	//End any sheets
	[NSApp endSheet:addContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:removeContactWindow returnCode:NSCancelButton];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[buddies release];
	[buddieGroups release];
	
	[[self window] close];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(accountManagerDidAddAccount:) name:JIMAccountManagerDidAddNewAccountNotification object:nil];
	[nc addObserver:self selector:@selector(accountManagerDidRemoveAccount:) name:JIMAccountManagerDidRemoveAccountNotification object:nil];
	[nc addObserver:self selector:@selector(accountDidConnect:) name:JIMAccountDidConnectNotification object:nil];
	
	[rosterTable setTarget:self];
	[rosterTable setDoubleAction:@selector(startChat:)];
	JIMOutlineCell *contactCell = [[[JIMOutlineCell alloc] init] autorelease];
	[[rosterTable tableColumnWithIdentifier:@"Name"] setDataCell:contactCell];
	
	[[self window] makeKeyAndOrderFront:self];
}

- (NSMutableArray *)buddies
{
	if (buddies == nil)
	{
		NSMutableArray *onlineArray = [[NSMutableArray alloc] initWithCapacity:5];
		NSMutableArray *offlineArray = [[NSMutableArray alloc] initWithCapacity:5];
		
		buddies = [[NSMutableArray alloc] initWithCapacity:5];
		[buddies addObject:onlineArray];
		[buddies addObject:offlineArray];
		
		[onlineArray release];
		[offlineArray release];
	}
	
	return buddies;
}

- (void)sortBuddies
{
	for(XMPPUser *oneUser in [[self buddies] objectAtIndex:0])
	{
		if(![oneUser isOnline])
		{
			[[[self buddies] objectAtIndex:1] addObject:oneUser];
			[[[self buddies] objectAtIndex:0] removeObject:oneUser];
		}
	}
	
	for(XMPPUser *oneUser in [[self buddies] objectAtIndex:1])
	{
		if([oneUser isOnline])
		{
			[[[self buddies] objectAtIndex:0] addObject:oneUser];
			[[[self buddies] objectAtIndex:1] removeObject:oneUser];
		}
	}
}

- (IBAction)setStatus:(id)sender
{
	if([[sender titleOfSelectedItem] isEqualToString:@"Offline"])
	{
		JIMAccount *oneAccount;
		for(oneAccount in accountManager.accounts)
			[oneAccount goOffline];
	}
	else
	{
		JIMAccount *oneAccount;
		for(oneAccount in accountManager.accounts)
		{
			if(![oneAccount.xmppService isAuthenticated])
				[oneAccount.xmppService authenticateUser];
			
			if([[sender titleOfSelectedItem] isEqualToString:@"Available"])
				[oneAccount setShow:XMPPPresenceShowAvailable andStatus:nil];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Away"])
				[oneAccount setShow:XMPPPresenceShowAway andStatus:@"Away"];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Chat"])
				[oneAccount setShow:XMPPPresenceShowChat andStatus:@"I want to chat"];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Extended away"])
				[oneAccount setShow:XMPPPresenceShowExtendedAway andStatus:@"Extended away"];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Do not Disturb"])
				[oneAccount setShow:XMPPPresenceShowDoNotDisturb andStatus:@"Do not Disturb"];
		}
	}
}

- (IBAction)segmentedToolsButton:(id)sender
{
	if([sender selectedSegment] == 0)
	{
		if([accountsButton numberOfItems] > 0)
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
	{
		[NSApp beginSheet:joinChatroomWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(joinChatroomSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
		[NSApp runModalForWindow:joinChatroomWindow];
		[NSApp endSheet:joinChatroomWindow];
		[joinChatroomWindow orderOut:self];
	}
}

- (IBAction)mainMenuItemPressed:(id)sender
{
	if([sender tag] == 43)
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
	if([rosterTable selectedRow] > -1 && [rosterTable levelForRow:[rosterTable selectedRow]] > 0)
	{
		[jidToRemove setStringValue:[[[rosterTable itemAtRow:[rosterTable selectedRow]] jid] fullString]];
		[nicknameToRemove setStringValue:[[rosterTable itemAtRow:[rosterTable selectedRow]] displayName]];
		[contactImageToRemove setImage:[[rosterTable itemAtRow:[rosterTable selectedRow]] image]];
		
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
	if([rosterTable selectedRow] > -1 && [rosterTable levelForRow:[rosterTable selectedRow]] > 0)
		[contactInfoController setXmppUser:[rosterTable itemAtRow:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)startChat:(id)sender
{
	if([rosterTable selectedRow] > -1 && [rosterTable levelForRow:[rosterTable selectedRow]] > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:[rosterTable itemAtRow:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)okSheet:(id)sender
{
	[NSApp endSheet:addContactWindow returnCode:NSOKButton];
	[NSApp endSheet:removeContactWindow returnCode:NSOKButton];
	[NSApp endSheet:joinChatroomWindow returnCode:NSOKButton];
}

- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:addContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:removeContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:joinChatroomWindow returnCode:NSCancelButton];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Roster Table Data Source:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
{
	if(item)
		return [item count];
	
	BOOL hasAUser = NO;
	for(NSArray *oneGroupArray in [self buddies])
		if([oneGroupArray count] != 0)
			hasAUser = YES;
	
	if(hasAUser)
		return [[self buddies] count];
	else
		return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
{
	if(item)
		return [[(NSArray *)item sortedArrayUsingSelector:@selector(compareByAvailabilityName:)] objectAtIndex:index];	
	
	return [[self buddies] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
{
	if([item isKindOfClass:[NSMutableArray class]])
		return YES;
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)user;
{
	if([user isKindOfClass:[XMPPUser class]])
	{
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
	}
	else //From now on user is a NSArray
	{
		JIMCell *itemCell = [[rosterTable tableColumnWithIdentifier:@"Name"] dataCell];
		[itemCell setTitle:[buddieGroups objectAtIndex:[[self buddies] indexOfObject:user]]];
		[itemCell setSubtitle:nil];
		[itemCell setImage:nil];
		[itemCell setStatusImage:nil];
		[itemCell setEnabled:NO];
	}
	
	return nil;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if([rosterTable isExpandable:item])
		return 17.;
	
	return 27.;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if([outlineView isExpandable:item])
        return NO;
    else
        return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if([item isKindOfClass:[XMPPUser class]])
	{
		if([item isOnline])
			[cell setEnabled:YES];
		else
			[cell setEnabled:NO];
	}
	else
		[cell setEnabled:NO];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sheet Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		XMPPService *serviceForAdding;
		for(JIMAccount *oneAccount in accountManager.accounts)
			if([[oneAccount.xmppService.myJID bareString] isEqualToString:[accountsButton titleOfSelectedItem]])
				serviceForAdding = oneAccount.xmppService;
		
		if(serviceForAdding)
		{
			XMPPSubscriptionRequest *request = [[[XMPPSubscriptionRequest alloc] initWithToJID:[XMPPJID jidWithString:[newContactJIDField stringValue]] service:serviceForAdding] autorelease];
			[request send];
		}
		else
			NSBeep();
	}
}

- (void)removeContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		XMPPUser *userForRemoval = [rosterTable itemAtRow:[rosterTable selectedRow]];
		[userForRemoval unsubscribe];
		[userForRemoval deleteFromRoster];
	}
}

- (void)joinChatroomSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		if(![[newChatroomName stringValue] isEqualToString:@""])
		{
			XMPPService *serviceForJoining;
			for(JIMAccount *oneAccount in accountManager.accounts)
				if([[oneAccount.xmppService.myJID bareString] isEqualToString:[accountsButton titleOfSelectedItem]])
					serviceForJoining = oneAccount.xmppService;
			
			if(serviceForJoining)
			{
				XMPPRoom *chatroom = [XMPPRoom roomWithJID:[XMPPJID jidWithString:[newChatroomName stringValue]] service:serviceForJoining];
				[chatroom enter];
				[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:chatroom];
			}
			else
				NSBeep();
		}
		else
			NSBeep();
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPAccountManager/XMPPAccount Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)accountManagerDidAddAccount:(NSNotification *)note
{
	[accountsButton removeAllItems];
	[accountsButton2 removeAllItems];
	
	JIMAccount *oneAccount;
	for(oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[accountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[accountsButton2 addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

- (void)accountManagerDidRemoveAccount:(NSNotification *)note
{
	[accountsButton removeAllItems];
	[accountsButton2 removeAllItems];
	
	JIMAccount *oneAccount;
	for(oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[accountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[accountsButton2 addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

- (void)accountDidConnect:(NSNotification *)note
{
	[accountsButton removeAllItems];
	[accountsButton2 removeAllItems];
	
	JIMAccount *oneAccount;
	for(oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[accountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[accountsButton2 addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRoster Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)rosterDidAddUsers:(NSNotification *)note
{
	NSSet *addedUsers = [note users];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	for (XMPPUser *user in addedUsers)
	{
		if([user isOnline])
			[[[self buddies] objectAtIndex:0] addObject:user];
		else
			[[[self buddies] objectAtIndex:1] addObject:user];
		
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
		
		if([user isOnline])
			[[[self buddies] objectAtIndex:0] removeObject:user];
		else
			[[[self buddies] objectAtIndex:1] removeObject:user];
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

@end
