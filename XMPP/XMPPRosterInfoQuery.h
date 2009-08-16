//  XMPPRosterInfoQuery.h
//  An concrete InfoQuery for jabber:iq:roster

#import "XMPPInfoQuery.h"

@class XMPPRosterItemElement;

@interface XMPPRosterInfoQuery : XMPPInfoQuery

+ (BOOL)stanzaHasRosterIQ:(XMPPStanza *)aStanza;

- (id)initWithType:(XMPPIQType)type service:(XMPPService *)service;	// Designated initializer

- (NSSet *)items;

- (void)addItem:(XMPPRosterItemElement *)item;

@end
