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

extern NSString* const JIMAccountDidFailToConnectNotification;
extern NSString* const JIMAccountDidConnectNotification;

@interface JIMAccount : NSObject {
	XMPPChatService *xmppService;
	NSDictionary *accountDict;
	NSString *error;
}

@property (readonly) XMPPChatService *xmppService;
@property (readonly) NSDictionary *accountDict;
@property (assign) NSString *error;

- (id)initWithAccountDict:(NSDictionary *)newAccountDict;

@end
