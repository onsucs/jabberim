//
//  JIMChatController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMSmallCell.h>
#import <XMPP/XMPP.h>

@interface JIMChatController : NSObject {
	IBOutlet NSView *chatView;
	IBOutlet NSSplitView *chatSplitView;
	IBOutlet NSSplitView *chatTextFieldSplitView;
	
	IBOutlet NSTextView *oldMessagesField;
	IBOutlet NSTextField *newMessageField;
	IBOutlet NSPopUpButton *availableResources;
	
	IBOutlet NSTableView *chatMembersTable;
	
	XMPPChatSession *chatSession;
}

@property (readonly) NSView *chatView;
@property (readwrite, retain) XMPPChatSession *chatSession;

- (id)initWithChatPartner:(id<XMPPChatPartner>)aPartner message:(XMPPChatMessage *)aMessage;

- (IBAction)setResource:(id)sender;
- (IBAction)performSendMessage:(id)sender;

- (void)scrollToBottom;
- (void)appendMessage:(NSAttributedString *)messageStr alignment:(NSTextAlignment)alignment;
- (void)appendMessage:(NSAttributedString *)messageStr fromUserAsString:(NSString *)userStr alignment:(NSTextAlignment)alignment;
- (void)observeRoom;

@end
