//
//  JIMChatTextView.h
//  JabberIM
//
//  Created by Roland Moers on 04.10.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

@interface JIMChatTextView : NSTextView {
	XMPPJID *lastMessageFromJID;
}

#pragma mark Messages
- (void)appendString:(NSString *)string;
- (void)appendString:(NSString *)string alignment:(NSTextAlignment)alignment;
- (void)appendMessage:(XMPPChatMessage *)message;
- (void)appendMessage:(XMPPChatMessage *)message alignment:(NSTextAlignment)alignment;

#pragma mark Others
- (void)scrollToBottom;

@end
