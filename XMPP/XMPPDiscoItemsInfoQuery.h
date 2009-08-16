//
//  An InfoQuery for http://jabber.org/protocol/disco#items
//  XEP-0030

#import "XMPPInfoQuery.h"

@interface XMPPDiscoItemsInfoQuery : XMPPInfoQuery 

- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid node:(NSString *)node service:(XMPPService *)service;

- (NSSet *)items;

@end
