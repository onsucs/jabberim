//
//  XMPPSubscriptionRequest.h
//  A request for unsubscription RFC 3921 6.4

#import "XMPPPresence.h"

@class XMPPPresenceStanza;
@class XMPPJID;
@class XMPPService;

@interface XMPPUnsubscriptionRequest : XMPPPresence

- (XMPPUnsubscriptionRequest *)initWithToJID:(XMPPJID *)aJID service:(XMPPService *)service;

@end
