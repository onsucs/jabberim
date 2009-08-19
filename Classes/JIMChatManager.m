//
//  JIMChatManager.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatManager.h"

NSString* const JIMChatManagerCreateNewChat = @"JIMChatManagerCreateNewChat";

@implementation JIMChatManager

@synthesize selectedChatView;

- (id)init
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMChatManager" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		chatControllerArray = [[NSMutableArray alloc] initWithCapacity:3];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(createChat:) name:JIMChatManagerCreateNewChat object:nil];
		[nc addObserver:self selector:@selector(chatDidReceiveMessage:) name:XMPPChatSessionDidReceiveMessageNotification object:nil];
		[nc addObserver:self selector:@selector(userDidChangeChatState:) name:XMPPUserDidChangeChatStateNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[chatControllerArray release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	JIMCell *contactCell = [[[JIMCell alloc] init] autorelease];
	[[chatControllerTable tableColumnWithIdentifier:@"Name"] setDataCell:contactCell];
	
	chatControllerArray = [[NSMutableArray alloc] initWithCapacity:3];
}

#pragma mark IBActions:
- (IBAction)stopChat:(id)sender
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:XMPPUserDidChangePresenceNotification object:[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatSession].chatPartner];
	[nc removeObserver:self name:XMPPUserDidChangeNameNotification object:[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatSession].chatPartner];
	
	[chatControllerArray removeObjectAtIndex:[chatControllerTable selectedRow]];
	[chatControllerTable reloadData];
	
	if([chatControllerArray count] <= 0)
		[chatWindow close];
}

- (IBAction)performInvite:(id)sender
{
	//if([[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatSession] isGroupChat])
	//{
		[NSApp beginSheet:inviteUserWindow modalForWindow:chatWindow modalDelegate:self didEndSelector:@selector(inviteUserSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
		[NSApp runModalForWindow:inviteUserWindow];
		[NSApp endSheet:inviteUserWindow];
		[inviteUserWindow orderOut:self];
	/*}
	else
	{
		NSAlert *errorSheet = [NSAlert alertWithMessageText:@"Invitation not possible"
											  defaultButton:nil
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:@"You cannot invite users into a private chat!"];
		
		[errorSheet beginSheetModalForWindow:chatWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}*/
}

- (IBAction)okSheet:(id)sender
{
	[NSApp endSheet:inviteUserWindow returnCode:NSOKButton];
}

- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:inviteUserWindow returnCode:NSCancelButton];
}

- (void)setSelectedChatView:(NSView *)newView
{
	[selectedChatView removeFromSuperview];
	selectedChatView = newView;
	
	NSRect chatControllerViewFrame = NSMakeRect(selectedChatView.frame.origin.x,
												selectedChatView.frame.origin.y,
												chatControllerView.frame.size.width,
												chatControllerView.frame.size.height);
	
	selectedChatView.frame = chatControllerViewFrame;
	[chatControllerView addSubview:self.selectedChatView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Chat Controller Table Data Source:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [chatControllerArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	JIMChatController *chatController = [chatControllerArray objectAtIndex:rowIndex];
	
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		JIMCell *itemCell = [[chatControllerTable tableColumnWithIdentifier:@"Name"] dataCell];
		
		if([chatController.chatSession.chatPartner isKindOfClass:[XMPPUser class]])
		{
			XMPPUser *user = chatController.chatSession.chatPartner;
			
			[itemCell setTitle:[user displayName]];
			[itemCell setImage:[user image]];
			
			if([user isOnline] && [user presenceShow] != XMPPPresenceShowUnknown)
			{
				if([user chatState] == XMPPChatStateComposing)
					[itemCell setStatusImage:[NSImage imageNamed:@"typing"]];
				else if([user chatState] == XMPPChatStatePaused)
					[itemCell setStatusImage:[NSImage imageNamed:@"enteredtext"]];
				else if([user presenceShow] == XMPPPresenceShowAvailable)
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
		else
		{
			[itemCell setTitle:[[chatController.chatSession.chatPartner jid] fullString]];
			[itemCell setSubtitle:nil];
			[itemCell setImage:[NSImage imageNamed:@"NSUserAccounts"]];
			[itemCell setStatusImage:nil];
			[itemCell setEnabled:YES];
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		if([[(JIMChatController *)[chatControllerArray objectAtIndex:rowIndex] chatSession].chatPartner isKindOfClass:[XMPPUser class]])
		{
			XMPPUser *user = [(JIMChatController *)[chatControllerArray objectAtIndex:rowIndex] chatSession].chatPartner;
			
			if([user isOnline])
				[cell setEnabled:YES];
			else
				[cell setEnabled:NO];
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([chatControllerArray count] == 0)
		return;
	
	self.selectedChatView = [(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatView];
}

#pragma mark Notifications:
- (void)createChat:(NSNotification *)note
{
	id<XMPPChatPartner> chatPartner = [note object];
	for(JIMChatController *oneChatController in chatControllerArray)
		if([oneChatController.chatSession.chatPartner.jid isEqual:chatPartner.jid])
		{
			[chatControllerTable selectRow:[chatControllerArray indexOfObject:oneChatController] byExtendingSelection:NO];
			[chatWindow makeFirstResponder:oneChatController.chatView];
			[chatWindow makeKeyAndOrderFront:self];
			return;
		}
	
	
	if([[note object] isKindOfClass:[XMPPUser class]])
	{
		XMPPUser *user = [note object];
		
		JIMChatController *newChatController = [[JIMChatController alloc] initWithChatPartner:user message:nil];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:user];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeNameNotification object:user];
		
		[chatControllerArray addObject:newChatController];
		[chatControllerTable reloadData];
		
		self.selectedChatView = newChatController.chatView;
		[chatControllerTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[chatControllerArray indexOfObject:newChatController]] byExtendingSelection:NO];
		[chatWindow makeFirstResponder:newChatController.chatView];
		[chatWindow makeKeyAndOrderFront:self];
		[newChatController release];
	}
	else if([[note object] isKindOfClass:[XMPPRoom class]])
	{
		XMPPRoom *room = [note object];
		
		NSLog(@"Opening chatroom");
		NSLog(@"Room JID: %@", [[room jid] fullString]);
		
		JIMChatController *newChatController = [[JIMChatController alloc] initWithChatPartner:room message:nil];
		[chatControllerArray addObject:newChatController];
		[chatControllerTable reloadData];
		
		self.selectedChatView = newChatController.chatView;
		[chatControllerTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[chatControllerArray indexOfObject:newChatController]] byExtendingSelection:NO];
		[chatWindow makeFirstResponder:newChatController.chatView];
		[chatWindow makeKeyAndOrderFront:self];
		[newChatController release];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPService Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)chatDidReceiveMessage:(NSNotification *)note
{
	XMPPChatSession *searchedChatSession = [note object];
	
	if(![searchedChatSession isGroupChat])
	{
		//Check whether we already have an open chat session
		for(JIMChatController *oneChatController in chatControllerArray)
			if([[oneChatController.chatSession uniqueIdentifier] isEqualToString:[searchedChatSession uniqueIdentifier]])
				return;
		
		//Create new Chat
		XMPPUser *newUser = [[XMPPUserManager sharedManager] userForJID:searchedChatSession.currentJID service:searchedChatSession.service];
		JIMChatController *newChatController = [[JIMChatController alloc] initWithChatPartner:newUser message:[note chatMessage]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:XMPPChatSessionDidReceiveMessageNotification object:newChatController.chatSession];
		[chatControllerArray addObject:newChatController];
		[newChatController release];
		
		[chatControllerTable reloadData];
		
		if(![chatWindow isVisible])
			[chatControllerTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[chatWindow makeKeyAndOrderFront:self];
		
		NSSound *newMessageSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Received Message.aiff" byReference:YES];
		[newMessageSound play];
		[newMessageSound release];
	}
	else
	{
		//FIXME: Implement
	}
}

- (void)userDidChangeChatState:(NSNotification *)note
{
	[chatControllerTable reloadData];
}

- (void)userDidChange:(NSNotification *)note
{
	[chatControllerTable reloadData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSSound Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
{
	if(finishedPlaying)
		[sound release];
}

#pragma mark Sheet Delegate Methods:
- (void)inviteUserSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		if ([[inviteUserJID stringValue] length] > 0)
		{
			[[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatSession] inviteJID:[XMPPJID jidWithString:[inviteUserJID stringValue]] withReason:[inviteUserReason stringValue]];
			[inviteUserJID setStringValue:@""];
			[inviteUserReason setStringValue:@""];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSWindow Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)windowWillClose:(NSNotification *)notification
{
	self.selectedChatView = nil;
	[chatControllerArray removeAllObjects];
}

@end
