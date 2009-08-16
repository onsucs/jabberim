//
//  JIMChatController.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatController.h"

@implementation JIMChatController

@synthesize xmppUser;
@synthesize chatSession;
@synthesize chatView;

- (id)initWithUser:(XMPPUser *)user message:(XMPPChatMessage *)aMessage
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMChatController" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		self.xmppUser = user;
		
		[oldMessagesField setString:@""];
		NSAttributedString *as = [[[NSAttributedString alloc] initWithString:@"Chatting with resource: Highest Priority" attributes:nil] autorelease];
		[self appendMessage:as alignment:NSCenterTextAlignment];
		
		chatSession = [[[[XMPPChatManager sharedManager] chatSessionsForChatPartner:user] anyObject] retain];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(chatDidSendMessage:) name:XMPPChatSessionDidSendMessageNotification object:self.chatSession];
		[nc addObserver:self selector:@selector(chatDidReceiveMessage:) name:XMPPChatSessionDidReceiveMessageNotification object:self.chatSession];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:user];
		
		if ([self.chatSession isGroupChat])
		{
			//[self observeRoom];
		}
		else
		{
			[nc addObserver:self selector:@selector(chatDidBecomeGroupChat:) name:XMPPChatSessionDidBecomeGroupChatNotification object:nil];
			[nc addObserver:self selector:@selector(userDidChangeChatState:) name:XMPPUserDidChangeChatStateNotification object:user];
		}
		
		XMPPResource *aResource;
		for(aResource in [user sortedResources])
			[availableResources addItemWithTitle:[[aResource jid] fullString]];
		
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
	[xmppUser release];
	
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

#pragma mark Delegates

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

- (void)userDidChange:(NSNotification *)note
{
	NSString *selectedItem = [availableResources titleOfSelectedItem];
	
	XMPPResource *aResource;
	for(aResource in [xmppUser sortedResources])
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

@end
