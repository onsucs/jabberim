//
//  JIMAccount.h
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMService.h>

extern NSString* const JIMAccountDidConnectNotification;
extern NSString* const JIMAccountDidFailToConnectNotification;
extern NSString* const JIMAccountDidFailToRegisterNotification;
extern NSString* const JIMAccountDidRefreshListOfChatroomsNotification;
extern NSString* const JIMAccountDidChangeStatusNotification;

@interface JIMAccount : NSObject {
	NSMutableDictionary *accountDict;
	NSString *error;
	
	XMPPChatService *xmppService;
	XMPPPresenceShow show;
	
	NSMutableArray *services;
	NSMutableArray *chatrooms;
}

@property (readonly) NSMutableDictionary *accountDict;
@property (readonly) NSString *error;
@property (readonly) XMPPChatService *xmppService;
@property (readonly) XMPPPresenceShow show;

#pragma mark Init
- (id)initWithAccountDict:(NSDictionary *)newAccountDict;

#pragma mark Status
- (void)setShow:(XMPPPresenceShow)newShow andStatus:(NSString *)newStatus;
- (void)goOffline;

#pragma mark Services and Features
- (NSArray *)services;
- (JIMService *)serviceForFeature:(NSString *)feature;
- (NSArray *)servicesWithFeature:(NSString *)feature;

#pragma mark Multi-User Chat
- (NSArray *)chatrooms;
- (NSArray *)chatroomForName:(NSString *)name;
- (void)refreshChatrooms;

@end
