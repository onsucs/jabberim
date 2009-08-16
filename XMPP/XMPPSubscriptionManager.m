#import "XMPPSubscriptionManager.h"
#import "XMPPPresenceStanza.h"
#import "XMPPSubscriptionRequest.h"

@interface XMPPSubscriptionManager ()
@property (nonatomic, readonly) NSMutableSet *requests;
@end

@implementation XMPPSubscriptionManager

+ (XMPPSubscriptionManager *)sharedManager
{
	static XMPPSubscriptionManager *sharedManager = nil;
	if (sharedManager == nil)
	{
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (void)serviceDidReceivePresenceStanza:(NSNotification *)note
{
	XMPPPresenceStanza *stanza = (XMPPPresenceStanza *)[note stanza];
	if ([XMPPSubscriptionRequest stanzaHasSubscriptionRequest:stanza])
	{
		XMPPSubscriptionRequest *request = [[[XMPPSubscriptionRequest alloc] initWithPresenceStanza:stanza service:[note object]] autorelease];
		[self.requests addObject:request];
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPSubscriptionRequestDidArriveNotification object:request];
	}
}
	
- (NSMutableSet *)requests
{
	if (_requests == nil)
	{
		_requests = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return _requests;
}		

@end
