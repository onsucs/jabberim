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
		[nc addObserver:self selector:@selector(createNewChat:) name:JIMChatManagerCreateNewChat object:nil];
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

- (void)createNewChat:(NSNotification *)note
{
	XMPPUser *user = [note object];
	
	JIMChatController *oneChatController;
	for(oneChatController in chatControllerArray)
	{
		if([oneChatController.xmppUser isEqual:user])
		{
			[chatControllerTable selectRow:[chatControllerArray indexOfObject:oneChatController] byExtendingSelection:NO];
			[chatWindow makeFirstResponder:oneChatController.chatView];
			[chatWindow makeKeyAndOrderFront:self];
			return;
		}
	}
	
	JIMChatController *newChatController = [[JIMChatController alloc] initWithUser:user message:nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:newChatController.xmppUser];
	[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeNameNotification object:newChatController.xmppUser];
	
	[chatControllerArray addObject:newChatController];
	[chatControllerTable reloadData];
	
	self.selectedChatView = newChatController.chatView;
	[chatControllerTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[chatControllerArray indexOfObject:newChatController]] byExtendingSelection:NO];
	[chatWindow makeFirstResponder:oneChatController.chatView];
	[chatWindow makeKeyAndOrderFront:self];
	[newChatController release];
}

- (IBAction)stopChat:(id)sender
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:XMPPUserDidChangePresenceNotification object:[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] xmppUser]];
	[nc removeObserver:self name:XMPPUserDidChangeNameNotification object:[(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] xmppUser]];
	
	[chatControllerArray removeObjectAtIndex:[chatControllerTable selectedRow]];
	[chatControllerTable reloadData];
	
	if([chatControllerArray count] <= 0)
		[chatWindow close];
}

- (void)setSelectedChatView:(NSView *)newView
{
	[selectedChatView removeFromSuperview];
	[selectedChatView release];
	selectedChatView = newView;
	[selectedChatView retain];
	
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
		
		[itemCell setTitle:[chatController.xmppUser displayName]];
		[itemCell setImage:[chatController.xmppUser image]];
		
		if([chatController.xmppUser isOnline] && [chatController.xmppUser presenceShow] != XMPPPresenceShowUnknown)
		{
			if([chatController.xmppUser chatState] == XMPPChatStateComposing)
				[itemCell setStatusImage:[NSImage imageNamed:@"typing"]];
			else if([chatController.xmppUser chatState] == XMPPChatStatePaused)
				[itemCell setStatusImage:[NSImage imageNamed:@"enteredtext"]];
			else if([chatController.xmppUser presenceShow] == XMPPPresenceShowAvailable)
				[itemCell setStatusImage:[NSImage imageNamed:@"available"]];
			else if([chatController.xmppUser presenceShow] == XMPPPresenceShowChat)
				[itemCell setStatusImage:[NSImage imageNamed:@"available"]];
			else if([chatController.xmppUser presenceShow] == XMPPPresenceShowAway)
				[itemCell setStatusImage:[NSImage imageNamed:@"away"]];
			else if([chatController.xmppUser presenceShow] == XMPPPresenceShowExtendedAway)
				[itemCell setStatusImage:[NSImage imageNamed:@"away"]];
			else if([chatController.xmppUser presenceShow] == XMPPPresenceShowDoNotDisturb)
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
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		XMPPUser *user = [(JIMChatController *)[chatControllerArray objectAtIndex:rowIndex] chatSession].chatPartner;
		
		if([user isOnline])
			[cell setEnabled:YES];
		else
			[cell setEnabled:NO];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([chatControllerArray count] == 0)
		return;
	
	self.selectedChatView = [(JIMChatController *)[chatControllerArray objectAtIndex:[chatControllerTable selectedRow]] chatView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPClient Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)chatDidReceiveMessage:(NSNotification *)note
{
	//Check whether we already have an open chat session
	XMPPChatSession *searchedChatSession = [note object];
	JIMChatController *oneChatController;
	for(oneChatController in chatControllerArray)
		if([[oneChatController.chatSession uniqueIdentifier] isEqualToString:[searchedChatSession uniqueIdentifier]])
			return;
	
	//Create new Chat
	XMPPUser *newUser = [[XMPPUserManager sharedManager] userForJID:searchedChatSession.currentJID service:searchedChatSession.service];
	JIMChatController *newChatController = [[JIMChatController alloc] initWithUser:newUser message:[note chatMessage]];
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSWindow Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)windowWillClose:(NSNotification *)notification
{
	self.selectedChatView = nil;
	[chatControllerArray removeAllObjects];
}

@end
