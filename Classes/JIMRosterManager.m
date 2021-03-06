//
//  JIMRosterManager.m
//  JabberIM
//
//  Created by Roland Moers on 16.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMRosterManager.h"

extern NSSound *buddieOnlineSound;
extern NSSound *buddieOfflineSound;

@interface JIMRosterManager ()
- (void)sortBuddies;
- (JIMAccount *)accountForJIDString:(NSString *)string;
- (JIMGroup *)groupWithName:(NSString *)groupName;
@end

@implementation JIMRosterManager

@synthesize groups;

#pragma mark Init and Dealloc
- (id)init
{
	if((self = [super initWithWindowNibName:@"JIMRosterManager"]))
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(rosterDidAddUsers:) name:XMPPRosterDidAddUsersNotification object:nil];
		[nc addObserver:self selector:@selector(rosterDidRemoveUsers:) name:XMPPRosterDidRemoveUsersNotification object:nil];
		
		groups = [[NSMutableArray alloc] init];
		JIMGroup *noGroupGroup = [[JIMGroup alloc] initWithName:@"Not grouped"];
		JIMGroup *offlineGroup = [[JIMGroup alloc] initWithName:@"Offline"];
		[groups addObject:noGroupGroup];
		[groups addObject:offlineGroup];
		[noGroupGroup release];
		[offlineGroup release];
	}
	return self;
}

- (void)awakeFromNib
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(accountManagerDidAddAccount:) name:JIMAccountManagerDidAddNewAccountNotification object:nil];
	[nc addObserver:self selector:@selector(accountManagerDidRemoveAccount:) name:JIMAccountManagerDidRemoveAccountNotification object:nil];
	[nc addObserver:self selector:@selector(accountDidConnect:) name:JIMAccountDidConnectNotification object:nil];
	[nc addObserver:self selector:@selector(accountDidChangeStatus:) name:JIMAccountDidChangeStatusNotification object:nil];
	
	[rosterTable setTarget:self];
	[rosterTable setDoubleAction:@selector(startChat:)];
	JIMOutlineCell *contactCell = [[[JIMOutlineCell alloc] init] autorelease];
	[[rosterTable tableColumnWithIdentifier:@"Name"] setDataCell:contactCell];
	
	[existingChatroomsTable setTarget:self];
	[existingChatroomsTable setDoubleAction:@selector(joinExistingChatroom:)];
	
	[statusButton selectItemWithTag:6];
	
	[[self window] makeKeyAndOrderFront:self];
}

- (void)dealloc
{
	[NSApp endSheet:addContactWindow returnCode:NSCancelButton];
	[NSApp endSheet:removeContactWindow returnCode:NSCancelButton];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[groups release];
	
	[[self window] close];
	
	[super dealloc];
}

#pragma mark Buttons
- (IBAction)chatroomAccountButton:(id)sender
{
	JIMAccount *selectedAccount = [self accountForJIDString:[sender titleOfSelectedItem]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JIMAccountDidRefreshListOfChatroomsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidRefreshListOfChatrooms:) name:JIMAccountDidRefreshListOfChatroomsNotification object:selectedAccount];
	
	[selectedAccount refreshChatrooms];
	[[newChatroomService cell] setPlaceholderString:[[[selectedAccount serviceForFeature:@"http://jabber.org/protocol/muc"] jid] fullString]];
	
	[existingChatroomsTable reloadData];
}


- (IBAction)showContactInfos:(id)sender
{
	if([rosterTable selectedRow] > -1 && [rosterTable levelForRow:[rosterTable selectedRow]] > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMBuddieInfoControllerShowUserNotification object:[rosterTable itemAtRow:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)setStatus:(id)sender
{
	if([[sender titleOfSelectedItem] isEqualToString:@"Offline"])
	{
		JIMAccount *oneAccount;
		for(oneAccount in [accountManager enabledAccounts])
			[oneAccount goOffline];
	}
	else
	{
		JIMAccount *oneAccount;
		for(oneAccount in [accountManager enabledAccounts])
		{
			if(![oneAccount.xmppService isAuthenticated])
				[oneAccount.xmppService authenticateUser];
			
			if([[sender titleOfSelectedItem] isEqualToString:@"Available"])
				[oneAccount setShow:XMPPPresenceShowAvailable andStatus:nil];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Away"])
				[oneAccount setShow:XMPPPresenceShowAway andStatus:@"Away"];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Chat"])
				[oneAccount setShow:XMPPPresenceShowChat andStatus:@"I want to chat"];
			else if([[sender titleOfSelectedItem] isEqualToString:@"Away (Extended)"])
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
		if([newContactAccountsButton numberOfItems] > 0)
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
		JIMAccount *selectedAccount = [self accountForJIDString:[chatroomAccountsButton titleOfSelectedItem]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidRefreshListOfChatrooms:) name:JIMAccountDidRefreshListOfChatroomsNotification object:selectedAccount];
		[selectedAccount refreshChatrooms];
		
		[newChatroomName setStringValue:@""];
		[newChatroomService setStringValue:@""];
		[[newChatroomService cell] setPlaceholderString:[[[selectedAccount serviceForFeature:@"http://jabber.org/protocol/muc"] jid] fullString]];
		
		[NSApp beginSheet:joinChatroomWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(joinChatroomSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
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

#pragma mark Start chat
- (IBAction)startChat:(id)sender
{
	if([rosterTable selectedRow] > -1 && [rosterTable levelForRow:[rosterTable selectedRow]] > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:[rosterTable itemAtRow:[rosterTable selectedRow]]];
	else
		NSBeep();
}

- (IBAction)joinExistingChatroom:(id)sender
{
	[NSApp endSheet:joinChatroomWindow returnCode:NSOKButton];
}

#pragma mark Sheet Methods
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

#pragma mark Roster Table
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
{
	if(item)
	{
		if([item isKindOfClass:[JIMGroup class]])
			return [[(JIMGroup *)item users] count];
		else return 0;
	}
	else return [groups count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
{
	if(item)
	{
		if([item isKindOfClass:[JIMGroup class]])
			return [[[(JIMGroup *)item users] sortedArrayUsingSelector:@selector(compareByAvailabilityName:)] objectAtIndex:index];
		else return 0;
	}
	
	return [[groups sortedArrayUsingSelector:@selector(compareByName:)] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
{
	if([item isKindOfClass:[JIMGroup class]])
		return YES;
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
{
	JIMCell *itemCell = [tableColumn dataCell];
	
	if([item isKindOfClass:[XMPPUser class]])
	{
		XMPPUser *user = item;
		
		if([[tableColumn identifier] isEqualToString:@"Name"])
		{
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
	else if([item isKindOfClass:[JIMGroup class]])
	{
		JIMGroup *group = item;
		
		[itemCell setTitle:group.name];
		[itemCell setSubtitle:nil];
		[itemCell setImage:nil];
		[itemCell setStatusImage:nil];
		[itemCell setEnabled:NO];
	}
	
	return itemCell;
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
		else [cell setEnabled:NO];
	}
	else
	{
		[cell setEnabled:NO];
		//if(![[(JIMGroup *)item name] isEqualToString:@"Offline"])
		//	[rosterTable expandItem:item];
	}
}

#pragma mark Chatroom Table
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	JIMAccount *accountOfChatrooms = nil;
	for(JIMAccount *oneAccount in accountManager.accounts)
		if([[oneAccount.xmppService.myJID bareString] isEqualToString:[chatroomAccountsButton titleOfSelectedItem]])
			accountOfChatrooms = oneAccount;
	
	if(accountOfChatrooms)
		return [[accountOfChatrooms chatrooms] count];
	
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	JIMAccount *accountOfChatrooms = nil;
	for(JIMAccount *oneAccount in accountManager.accounts)
		if([[oneAccount.xmppService.myJID bareString] isEqualToString:[chatroomAccountsButton titleOfSelectedItem]])
			accountOfChatrooms = oneAccount;
	
	if(accountOfChatrooms)
	{
		if([[tableColumn identifier] isEqualToString:@"Name"])
			return [(XMPPDiscoItemsItemElement *)[[accountOfChatrooms chatrooms] objectAtIndex:rowIndex] name];
		else if([[tableColumn identifier] isEqualToString:@"JID"])
			return [[(XMPPDiscoItemsItemElement *)[[accountOfChatrooms chatrooms] objectAtIndex:rowIndex] jid] fullString];
	}
	
	return @"";
}

#pragma mark JIMAccountManager/JIMAccount Delegate
- (void)accountManagerDidAddAccount:(NSNotification *)note
{
	[newContactAccountsButton removeAllItems];
	[chatroomAccountsButton removeAllItems];
	
	JIMAccount *oneAccount;
	for(oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[newContactAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[chatroomAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

- (void)accountManagerDidRemoveAccount:(NSNotification *)note
{
	[newContactAccountsButton removeAllItems];
	[chatroomAccountsButton removeAllItems];
	
	JIMAccount *oneAccount;
	for(oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[newContactAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[chatroomAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

- (void)accountDidConnect:(NSNotification *)note
{
	[newContactAccountsButton removeAllItems];
	[chatroomAccountsButton removeAllItems];
	
	for(JIMAccount *oneAccount in accountManager.accounts)
		if([oneAccount.xmppService isAuthenticated])
		{
			[newContactAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
			[chatroomAccountsButton addItemWithTitle:[oneAccount.xmppService.myJID bareString]];
		}
}

- (void)accountDidChangeStatus:(NSNotification *)note
{
	NSArray *enabledAccounts = [accountManager enabledAccounts];
	
	for(JIMAccount *oneAccount in enabledAccounts)
		if(oneAccount.show == XMPPPresenceShowAvailable)
		{
			[statusButton selectItemWithTag:1];
			return;
		}
	
	for(JIMAccount *oneAccount in enabledAccounts)
		if(oneAccount.show == XMPPPresenceShowChat)
		{
			[statusButton selectItemWithTag:2];
			return;
		}
	
	for(JIMAccount *oneAccount in enabledAccounts)
		if(oneAccount.show == XMPPPresenceShowDoNotDisturb)
		{
			[statusButton selectItemWithTag:5];
			return;
		}
	
	for(JIMAccount *oneAccount in enabledAccounts)
		if(oneAccount.show == XMPPPresenceShowExtendedAway)
		{
			[statusButton selectItemWithTag:4];
			return;
		}
	
	for(JIMAccount *oneAccount in enabledAccounts)
		if(oneAccount.show == XMPPPresenceShowAway)
		{
			[statusButton selectItemWithTag:3];
			return;
		}
	
	[statusButton selectItemWithTag:6];
}

- (void)accountDidRefreshListOfChatrooms:(NSNotification *)note
{
	[existingChatroomsTable reloadData];
}

#pragma mark XMPPRoster Delegate
- (void)rosterDidAddUsers:(NSNotification *)note
{
	NSSet *addedUsers = [note users];
	for (XMPPUser *oneUser in addedUsers)
	{
		[[self groupWithName:@"Offline"] addUser:oneUser];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeNameNotification object:oneUser];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeGroupsNotification object:oneUser];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:oneUser];
	}
	
	[self sortBuddies];
	[buddieOnlineSound play];
}

- (void)rosterDidRemoveUsers:(NSNotification *)note
{
	NSSet *removedUsers = [note users];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	for (XMPPUser *oneUser in removedUsers)
	{
		[nc removeObserver:self name:nil object:oneUser];
		
		for(JIMGroup *oneGroup in groups)
			[oneGroup removeUser:oneUser];
	}	
	
	[self sortBuddies];
	[buddieOfflineSound play];
}

- (void)userDidChange:(NSNotification *)note
{
	[self sortBuddies];
}

#pragma mark Sheet Delegate
- (void)addContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		XMPPService *serviceForAdding = nil;
		for(JIMAccount *oneAccount in accountManager.accounts)
			if([[oneAccount.xmppService.myJID bareString] isEqualToString:[newContactAccountsButton titleOfSelectedItem]])
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
	[joinChatroomWindow orderOut:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JIMAccountDidRefreshListOfChatroomsNotification object:nil];
	
	if(returnCode == NSOKButton)
	{
		if([chatroomTabView indexOfTabViewItem:[chatroomTabView selectedTabViewItem]] == 0)
		{
			if([existingChatroomsTable selectedRow] > -1)
			{
				JIMAccount *selectedAccount = [self accountForJIDString:[chatroomAccountsButton titleOfSelectedItem]];
				XMPPJID *selectedAccountJID = [(XMPPDiscoItemsItemElement *)[[selectedAccount chatrooms] objectAtIndex:[existingChatroomsTable selectedRow]] jid];
				XMPPRoom *chatroom = [XMPPRoom roomWithJID:selectedAccountJID  service:selectedAccount.xmppService];
				[chatroom enter];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:chatroom];
			}
			else
				NSBeep();
		}
		else
		{
			if(![[newChatroomName stringValue] isEqualToString:@""])
			{
				JIMAccount *selectedAccount = [self accountForJIDString:[chatroomAccountsButton titleOfSelectedItem]];
				XMPPRoom *chatroom;
				
				if([[newChatroomService stringValue] isEqualToString:@""])
					chatroom = [XMPPRoom roomWithJID:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", [newChatroomName stringValue], [[newChatroomService cell] placeholderString]]] service:selectedAccount.xmppService];
				else
					chatroom = [XMPPRoom roomWithJID:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", [newChatroomName stringValue], [newChatroomService stringValue]]] service:selectedAccount.xmppService];
				
				[chatroom enter];
				[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:chatroom];
			}
			else
				NSBeep();
		}
	}
}

#pragma mark NSMenu Delegate
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if([[menu itemWithTag:2] state] != NSOnState)
		[[menu itemWithTag:2] setState:NSOffState];
	if([[menu itemWithTag:3] state] != NSOnState)
		[[menu itemWithTag:3] setState:NSOffState];
	if([[menu itemWithTag:4] state] != NSOnState)
		[[menu itemWithTag:4] setState:NSOffState];
	if([[menu itemWithTag:5] state] != NSOnState)
		[[menu itemWithTag:5] setState:NSOffState];
	if([[menu itemWithTag:6] state] != NSOnState)
		[[menu itemWithTag:6] setState:NSOffState];
	
	
	for(JIMAccount *oneAccount in [accountManager enabledAccounts])
	{
		if(oneAccount.show == XMPPPresenceShowChat && [[menu itemWithTag:2] state] != NSOnState)
			[[menu itemWithTag:2] setState:NSMixedState];
		if(oneAccount.show == XMPPPresenceShowAway && [[menu itemWithTag:3] state] != NSOnState)
			[[menu itemWithTag:3] setState:NSMixedState];
		if(oneAccount.show == XMPPPresenceShowExtendedAway && [[menu itemWithTag:4] state] != NSOnState)
			[[menu itemWithTag:4] setState:NSMixedState];
		if(oneAccount.show == XMPPPresenceShowDoNotDisturb && [[menu itemWithTag:5] state] != NSOnState)
			[[menu itemWithTag:5] setState:NSMixedState];
		if(oneAccount.show == XMPPPresenceShowUnknown && [[menu itemWithTag:6] state] != NSOnState)
			[[menu itemWithTag:6] setState:NSMixedState];
	}
}

#pragma mark Private
- (void)sortBuddies
{
	for(JIMGroup *oneGroup in groups)
	{
		if([oneGroup.name isEqualToString:@"Offline"])
		{
			for(XMPPUser *oneUser in oneGroup.users)
			{
				if([oneUser isOnline])
				{
					if([[oneUser.groupNames allObjects] count] > 0)
						for(NSString *oneGroupName in [oneUser.groupNames allObjects])
						{
							JIMGroup *groupWithName = [self groupWithName:oneGroupName];
							[groupWithName addUser:oneUser];
							[rosterTable reloadItem:groupWithName];
						}
					else
					{
						JIMGroup *notGroupedGroup = [self groupWithName:@"Not grouped"];
						[notGroupedGroup addUser:oneUser];
						[rosterTable reloadItem:notGroupedGroup];
					}
					
					[oneGroup removeUser:oneUser];
					[rosterTable reloadItem:oneGroup];
				}
			}
		}
		else
		{
			for(XMPPUser *oneUser in oneGroup.users)
			{
				if(![oneUser isOnline])
				{
					JIMGroup *offlineGroup = [self groupWithName:@"Offline"];
					[offlineGroup addUser:oneUser];
					[oneGroup removeUser:oneUser];
					
					[rosterTable reloadItem:offlineGroup];
					[rosterTable reloadItem:oneGroup];
				}
				else
				{
					if(![oneUser.groupNames containsObject:oneGroup.name])
					{
						[oneGroup removeUser:oneUser];
						
						if([[oneUser.groupNames allObjects] count] > 0)
							for(NSString *oneGroupName in oneUser.groupNames)
							{
								JIMGroup *groupWithName = [self groupWithName:oneGroupName];
								[groupWithName addUser:oneUser];
								[rosterTable reloadItem:groupWithName];
							}
						else
						{
							JIMGroup *notGroupedGroup = [self groupWithName:@"Not grouped"];
							[notGroupedGroup addUser:oneUser];
							[rosterTable reloadItem:notGroupedGroup];
						}
						
						[oneGroup removeUser:oneUser];
						[rosterTable reloadItem:oneGroup];
					}
				}

			}
		}
	}
	
	NSMutableArray *groupsToRemove = [NSMutableArray array];
	
	for(JIMGroup *oneGroup in groups)
	{
		if([oneGroup.users count] < 1 && ![oneGroup.name isEqualToString:@"Not grouped"] && ![oneGroup.name isEqualToString:@"Offline"])
			[groupsToRemove addObject:oneGroup];
	}
	
	if([groupsToRemove count] > 0)
	{
		[groups removeObjectsInArray:groupsToRemove];
		[rosterTable reloadData];
	}
}

- (JIMAccount *)accountForJIDString:(NSString *)string
{
	for(JIMAccount *oneAccount in accountManager.accounts)
		if([[oneAccount.xmppService.myJID bareString] isEqualToString:string])
			return oneAccount;
	
	return nil;
}

- (JIMGroup *)groupWithName:(NSString *)groupName
{
	if(!groupName)
		return [self groupWithName:@"Not grouped"];
	
	for(JIMGroup *oneGroup in groups)
		if([oneGroup.name isEqualToString:groupName])
			return oneGroup;
	
	JIMGroup *newGroup = [[JIMGroup alloc] initWithName:groupName];
	[groups addObject:newGroup];
	[newGroup release];
	
	[rosterTable reloadData];
	
	return [self groupWithName:groupName];
}

@end
