#import "XMPPSubscriptionRequest.h"
#import "XMPPService.h"

NSString* const XMPPSubscriptionRequestDidArriveNotification = @"XMPPSubscriptionRequestDidArriveNotification";

@implementation XMPPSubscriptionRequest

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)stanzaHasSubscriptionRequest:(XMPPPresenceStanza *)stanza
{
	return ([stanza type] == XMPPPresenceTypeSubscribe);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPSubscriptionRequest *)initWithToJID:(XMPPJID *)aJID service:(XMPPService *)aService
{
	XMPPPresenceStanza *stanza = [[[XMPPPresenceStanza alloc] initWithFromJID:nil toJID:aJID type:XMPPPresenceTypeSubscribe] autorelease];
	return [super initWithPresenceStanza:stanza service:aService];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)approve
{
	XMPPPresenceStanza *stanza = [[[XMPPPresenceStanza alloc] initWithFromJID:nil toJID:self.fromJID type:XMPPPresenceTypeSubscribed] autorelease];
	[self.service sendStanza:stanza];
}

- (void)refuse
{
	XMPPPresenceStanza *stanza = [[[XMPPPresenceStanza alloc] initWithFromJID:nil toJID:self.fromJID type:XMPPPresenceTypeUnsubscribed] autorelease];
	[self.service sendStanza:stanza];
}

@end
