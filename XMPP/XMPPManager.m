#import "XMPPManager.h"
#import "XMPPService.h"

@implementation XMPPManager

- (NSMutableSet *)services
{
	if (_services == nil)
	{
		_services = [[NSMutableSet alloc] initWithCapacity:1];
	}
	return _services;
}

- (void)addService:(XMPPService *)aService
{
	[aService addObserverForRespondingNotifications:self];
	[self.services addObject:aService];
}

- (void)removeService:(XMPPService *)aService
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:aService];
	[self.services removeObject:aService];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_services release]; _services = nil;
	[super dealloc];
}

@end
