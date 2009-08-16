//  XMPPRoomOwnerInfoQuery.h
//  An concrete InfoQuery for http://jabber.org/protocol/muc#owner

#import "XMPPInfoQuery.h"

@class XMPPRoom;
@interface XMPPRoomOwnerInfoQuery : XMPPInfoQuery

- (id)initWithRoom:(XMPPRoom *)aRoom;	// Designated initializer

@end
