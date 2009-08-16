//
//  XMPPSubscriptionRequest.h
//  A request for subscription RFC 3921 6.1

#import "XMPPPresence.h"

extern NSString* const XMPPSubscriptionRequestDidArriveNotification;

@class XMPPPresenceStanza;

@interface XMPPSubscriptionRequest : XMPPPresence

+ (BOOL)stanzaHasSubscriptionRequest:(XMPPPresenceStanza *)stanza;

- (XMPPSubscriptionRequest *)initWithToJID:(XMPPJID *)aJID service:(XMPPService *)service;

- (void)approve;
- (void)refuse;

@end
