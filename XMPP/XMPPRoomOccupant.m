#import "XMPPRoomOccupant.h"
#import "XMPPResource.h"

NSString* const XMPPRoomOccupantDidLeaveRoomNotification = @"XMPPRoomOccupantDidLeaveRoomNotification";

static NSString* const RoomOccupantKey = @"roomOccupant";

@interface XMPPRoomOccupant ()
@property (nonatomic, readwrite, retain) XMPPResource *resource;
- (void)resourceDidBecomeUnavailable:(NSNotification *)note;
@end

@implementation XMPPRoomOccupant
@synthesize resource = _resource;

- (XMPPRoomOccupant *)initWithResource:(XMPPResource *)aResource
{
	self = [super init];
	if (self != nil)
	{
		self.resource = aResource;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDidBecomeUnavailable:) name:XMPPResourceDidBecomeUnavailableNotification object:aResource];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_resource release]; _resource = nil;
	[super dealloc];
}

- (NSString *)name
{
	return self.resource.name;
}

- (void)resourceDidBecomeUnavailable:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPRoomOccupantDidLeaveRoomNotification object:self];
}

@end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Categories
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSNotificationCenter (XMPPRoomOccupant)
- (void)postNotificationName:(NSString *)name object:(id)object roomOccupant:(XMPPRoomOccupant *)occupant
{
	[self postNotificationName:name object:object userInfo:[NSDictionary dictionaryWithObject:occupant forKey:RoomOccupantKey]];
}
@end

@implementation NSNotification (XMPPRoomOccupant)
- (XMPPRoomOccupant *)roomOccupant
{
	return [[self userInfo] objectForKey:RoomOccupantKey];
}
@end