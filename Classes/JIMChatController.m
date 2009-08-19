//
//  JIMChatController.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatController.h"

@implementation JIMChatController

@synthesize chatView;
@synthesize chatSession;

- (id)initWithChatPartner:(id<XMPPChatPartner>)aPartner message:(XMPPChatMessage *)aMessage
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMChatController" owner:self])
			NSLog(@"Error loading Nib for document!");
		
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
		}
		
		[oldMessagesField setString:@""];
		NSAttributedString *as = [[[NSAttributedString alloc] initWithString:@"Chatting with resource: Highest Priority" attributes:nil] autorelease];
		[self appendMessage:as alignment:NSCenterTextAlignment];
		
		if(aMessage)
			[self appendMessage:[aMessage attributedBody] alignment:NSLeftTextAlignment];
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

- (IBAction)setResource:(id)sender
{
	NSAttributedString *as = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Changed resource to: %@", [sender titleOfSelectedItem]] attributes:nil] autorelease];
	[self appendMessage:as alignment:NSCenterTextAlignment];
	
}

- (IBAction)performSendMessage:(id)sender
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

- (void)appendMessage:(NSAttributedString *)messageStr alignment:(NSTextAlignment)alignment
{
	NSMutableAttributedString *paragraph = [[messageStr mutableCopy] autorelease];
	[paragraph appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n"] autorelease]];	
	NSMutableParagraphStyle *mps = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mps setAlignment:alignment];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
	[attributes setObject:mps forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSColor colorWithCalibratedRed:250 green:250 blue:250 alpha:1] forKey:NSBackgroundColorAttributeName];	// FIXME: Not sure why this isn't doing anything
	
	[paragraph addAttributes:attributes range:NSMakeRange(0, [paragraph length])];
	
	[[oldMessagesField textStorage] appendAttributedString:paragraph];
	[self scrollToBottom];
}

- (void)scrollToBottom
{
	NSScrollView *scrollView = [oldMessagesField enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)observeRoom
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(roomDidAddOccupant:) name:XMPPRoomDidAddOccupantNotification object:self.chatSession.chatPartner];
	[nc addObserver:self selector:@selector(roomDidRemoveOccupant:) name:XMPPRoomDidRemoveOccupantNotification object:self.chatSession.chatPartner];
	[nc removeObserver:self name:XMPPUserDidChangePresenceNotification object:nil];
	[nc removeObserver:self name:XMPPUserDidChangeNameNotification object:nil];
	
	[chatMembersTable reloadData];
}

#pragma mark Chat Members Table:
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(self.chatSession.isGroupChat)
	{
		XMPPRoom *room = (XMPPRoom *)self.chatSession.chatPartner;	// FIXME: Non-group chats have occupants too
		return [room.occupants count];
	}
	else
		return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
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

#pragma mark Chat Session Delegates
- (void)chatDidSendMessage:(NSNotification *)note
{
	XMPPChatMessage *message = (XMPPChatMessage *)[note chatMessage];
	NSAttributedString *messageStr = [message attributedBody];
	[self appendMessage:messageStr alignment:NSRightTextAlignment];
	
	NSSound *newMessageSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Sent Message.aiff" byReference:YES];
	[newMessageSound play];
	[newMessageSound release];
}

- (void)chatDidReceiveMessage:(NSNotification *)note
{
	XMPPChatMessage *message = (XMPPChatMessage *)[note chatMessage];
	NSAttributedString *messageStr = [message attributedBody];
	[self appendMessage:messageStr alignment:NSLeftTextAlignment];
	
	NSSound *newMessageSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Received Message.aiff" byReference:YES];
	[newMessageSound play];
	[newMessageSound release];
}

- (void)chatDidBecomeGroupChat:(NSNotification *)note
{
	[chatSplitView setPosition:380 ofDividerAtIndex:0];
	
	[self observeRoom];
}

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
			chatStateString = [NSString stringWithFormat:@"%@ is ignoring us", user.displayName];
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
	{
		NSAttributedString *as = [[[NSAttributedString alloc] initWithString:chatStateString attributes:nil] autorelease];
		[self appendMessage:as alignment:NSCenterTextAlignment];
	}
}

- (void)roomDidAddOccupant:(NSNotification *)note
{
	[chatMembersTable reloadData];
}

- (void)roomDidRemoveOccupant:(NSNotification *)note
{
	[chatMembersTable reloadData];
}

@end
