//
//  JIMChatViewController.m
//  JabberIM
//
//  Created by Roland Moers on 04.10.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatViewController.h"

extern NSSound *newMessageRecievedSound;
extern NSSound *newMessageSendSound;

@interface JIMChatViewController ()
@property (readwrite, retain) XMPPChatSession *chatSession;
- (void)observeRoom;
@end

@implementation JIMChatViewController

@synthesize chatSession;

#pragma mark Init and Dealloc
- (id)initWithChatPartner:(id<XMPPChatPartner>)aPartner message:(XMPPChatMessage *)aMessage;
{
	if((self = [super initWithNibName:@"JIMChatViewController" bundle:[NSBundle mainBundle]]))
	{
		[self loadView];
		
		JIMSmallCell *buddieCell = [[[JIMSmallCell alloc] init] autorelease];
		[[chatMembersTable tableColumnWithIdentifier:@"Name"] setDataCell:buddieCell];
		
		self.chatSession = [[[XMPPChatManager sharedManager] chatSessionsForChatPartner:aPartner] anyObject];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(chatDidSendMessage:) name:XMPPChatSessionDidSendMessageNotification object:self.chatSession];
		[nc addObserver:self selector:@selector(chatDidReceiveMessage:) name:XMPPChatSessionDidReceiveMessageNotification object:self.chatSession];
		
		if ([self.chatSession isGroupChat])
		{
			[self observeRoom];
		}
		else
		{
			[nc addObserver:self selector:@selector(chatDidBecomeGroupChat:) name:XMPPChatSessionDidBecomeGroupChatNotification object:nil];
			[nc addObserver:self selector:@selector(userDidChangeChatState:) name:XMPPUserDidChangeChatStateNotification object:aPartner];
			[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:aPartner];
			
			for(XMPPResource *aResource in [(XMPPUser *)aPartner sortedResources])
				[availableResources addItemWithTitle:[[aResource jid] fullString]];
			
			[chatSplitView setPosition:[chatSplitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
			
			for(XMPPChatMessage *oneMessage in self.chatSession.messages)
				[chatTextView appendMessage:oneMessage];
			
			[chatTextView appendString:@"Chatting with resource: Highest Priority"];
		}
		
		if(aMessage)
			[chatTextView appendMessage:aMessage];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[chatSession leave];
	[chatSession release];
	
	[super dealloc];
}

#pragma mark Buttons
- (IBAction)setResource:(id)sender
{
	[chatTextView appendString:[NSString stringWithFormat:@"Changed resource to: %@", [sender titleOfSelectedItem]]];
}

- (IBAction)sendMessage:(id)sender
{
	if ([[sender stringValue] length] > 0)
	{
		if([[availableResources titleOfSelectedItem] isEqualToString:@"Highest Priority"])
			[self.chatSession sendString:[sender stringValue]];
		else
		{
			XMPPChatMessage *message = [[[XMPPChatMessage alloc] initWithTo:[XMPPJID jidWithString:[availableResources titleOfSelectedItem]] string:[sender stringValue] service:chatSession.chatPartner.service isGroupChat:chatSession.isGroupChat] autorelease];
			[chatSession sendMessage:message];
		}
		[sender setStringValue:@""];
	}
}

#pragma mark Chat Members Table
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(self.chatSession.isGroupChat)
	{
		XMPPRoom *room = (XMPPRoom *)self.chatSession.chatPartner;	// FIXME: Non-group chats have occupants too
		return [room.occupants count];
	}
	else
		return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		JIMCell *itemCell = [[chatMembersTable tableColumnWithIdentifier:@"Name"] dataCell];
		
		if (self.chatSession.isGroupChat)
		{
			XMPPRoom *room = (XMPPRoom *)self.chatSession.chatPartner;
			[itemCell setTitle:[[room.occupants objectAtIndex:rowIndex] name]];
			[itemCell setImage:[NSImage imageNamed:@"NSUser"]];
			[itemCell setEnabled:YES];
			
			return nil;
		}
		
		[itemCell setTitle:@""];
		[itemCell setImage:nil];
		[itemCell setEnabled:NO];
	}
	
	return nil;
}

#pragma mark XMPPChatSession Delegate
- (void)chatDidSendMessage:(NSNotification *)note
{
	[chatTextView appendMessage:[note chatMessage]];
	[newMessageSendSound play];
}

- (void)chatDidReceiveMessage:(NSNotification *)note
{
	[chatTextView appendMessage:[note chatMessage]];
	[newMessageRecievedSound play];
}

- (void)chatDidBecomeGroupChat:(NSNotification *)note
{
	[chatSplitView setPosition:380 ofDividerAtIndex:0];
	
	[self observeRoom];
}

#pragma mark XMPPUser Delegate
- (void)userDidChange:(NSNotification *)note
{
	NSString *selectedItem = [availableResources titleOfSelectedItem];
	XMPPUser *user = [note object];
	
	for(XMPPResource *aResource in [user sortedResources])
		[availableResources addItemWithTitle:[[aResource jid] fullString]];
	
	if([availableResources itemWithTitle:selectedItem])
		[availableResources selectItemWithTitle:selectedItem];
	else
		[availableResources selectItemWithTitle:@"Highest Priority"];
}

- (void)userDidChangeChatState:(NSNotification *)note
{
	NSString *chatStateString = nil;
	XMPPUser *user = [note object];
	switch ([(XMPPUser*)[note object] chatState])
	{
		case XMPPChatStateInactive:
			chatStateString = [NSString stringWithFormat:@"%@ is ignoring you", user.displayName];
			break;
		case XMPPChatStateGone:
			chatStateString = [NSString stringWithFormat:@"%@ has made a run for it", user.displayName];
			break;
		case XMPPChatStateUnknown:
		case XMPPChatStateActive:
		default:
			break;
	}
	
	if(chatStateString)
		[chatTextView appendString:chatStateString];
}

#pragma mark XMPPRoom Delegate
- (void)roomDidAddOccupant:(NSNotification *)note
{
	[chatMembersTable reloadData];
}

- (void)roomDidRemoveOccupant:(NSNotification *)note
{
	[chatMembersTable reloadData];
}

#pragma mark Private
- (void)observeRoom
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(roomDidAddOccupant:) name:XMPPRoomDidAddOccupantNotification object:self.chatSession.chatPartner];
	[nc addObserver:self selector:@selector(roomDidRemoveOccupant:) name:XMPPRoomDidRemoveOccupantNotification object:self.chatSession.chatPartner];
	[nc removeObserver:self name:XMPPUserDidChangePresenceNotification object:nil];
	[nc removeObserver:self name:XMPPUserDidChangeNameNotification object:nil];
	
	[chatMembersTable reloadData];
}

@end
