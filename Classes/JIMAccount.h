//
//  JIMAccount.h
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMChatManager.h>
#import <JIMContactInfoController.h>

extern NSString* const JIMAccountDidConnectNotification;
extern NSString* const JIMAccountDidFailToConnectNotification;
extern NSString* const JIMAccountDidFailToRegisterNotification;

@interface JIMAccount : NSObject {
	XMPPChatService *xmppService;
	NSMutableDictionary *accountDict;
	NSString *error;
	
	XMPPPresenceShow show;
}

@property (readonly) XMPPChatService *xmppService;
@property (readonly) NSMutableDictionary *accountDict;
@property (assign) NSString *error;
@property (assign) XMPPPresenceShow show;

- (id)initWithAccountDict:(NSDictionary *)newAccountDict;

- (void)setShow:(XMPPPresenceShow)newShow andStatus:(NSString *)newStatus;
- (void)goOffline;

@end
