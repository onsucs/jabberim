//
//  JIMChatController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

@interface JIMChatController : NSObject {
	//IBOutlet NSView *chatView;
	IBOutlet NSTextView *oldMessagesField;
	IBOutlet NSTextField *newMessageField;
	IBOutlet NSPopUpButton *availableResources;
	IBOutlet NSView *chatView;
	
	XMPPUser *xmppUser;
	XMPPChatSession *chatSession;
}

@property (retain) XMPPUser *xmppUser;
@property (readonly) XMPPChatSession *chatSession;
@property (readonly) NSView *chatView;

- (id)initWithUser:(XMPPUser *)user message:(XMPPChatMessage *)aMessage;

- (IBAction)setResource:(id)sender;
- (IBAction)performSendMessage:(id)sender;

- (void)scrollToBottom;
- (void)appendMessage:(NSAttributedString *)messageStr alignment:(NSTextAlignment)alignment;

@end
