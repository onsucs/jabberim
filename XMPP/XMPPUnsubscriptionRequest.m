#import "XMPPUnsubscriptionRequest.h"

@implementation XMPPUnsubscriptionRequest

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPUnsubscriptionRequest *)initWithToJID:(XMPPJID *)aJID service:(XMPPService *)aService
{
	XMPPPresenceStanza *stanza = [[[XMPPPresenceStanza alloc] initWithFromJID:nil toJID:aJID type:XMPPPresenceTypeUnsubscribe] autorelease];
	return [super initWithPresenceStanza:stanza service:aService];
}

@end
