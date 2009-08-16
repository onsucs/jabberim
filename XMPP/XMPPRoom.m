#import "XMPPRoom.h"
#import "XMPPService.h"
#import "XMPPJID.h"
#import "XMPPUser.h"
#import "XMPPRoomOccupant.h"
#import "XMPPResource.h"
#import "XMPPRoomOwnerInfoQuery.h"

NSString* const XMPPRoomDidInviteNotification = @"XMPPRoomDidInviteNotification";
NSString* const XMPPRoomDidAddOccupantNotification = @"XMPPRoomDidAddOccupantNotification";
NSString* const XMPPRoomDidRemoveOccupantNotification = @"XMPPRoomDidRemoveOccupantNotification";
NSString* const XMPPRoomDidEnterNotification = @"XMPPRoomDidEnterNotification";
NSString* const XMPPRoomDidLeaveNotification = @"XMPPRoomDidLeaveNotification";

@interface XMPPRoom ()
@property (nonatomic, readwrite, retain) XMPPJID *myRoomJID;
@property (nonatomic, readonly)	NSMutableDictionary *occupantsForResources;
@property (nonatomic, readwrite, assign) BOOL isJoined;
@property (nonatomic, readwrite, retain) XMPPUser *roomUser;

+ (NSMutableDictionary *)roomsForService:(XMPPService *)aService;
- (id)initWithJID:(XMPPJID *)aJid service:(XMPPService *)aService;
+ (void)addRoom:(XMPPRoom *)aRoom;
+ (NSMutableDictionary *)roomsForServices;
- (void)userDidChangePresence:(NSNotification *)note;
- (void)roomOccupantDidLeaveRoom:(NSNotification *)note;
@end

static NSString *const XMPPMUCNamespaceName = @"http://jabber.org/protocol/muc";

@implementation XMPPRoom
@synthesize myRoomJID = _myRoomJID;
@synthesize isJoined = _isJoined;
@synthesize roomUser = _roomUser;

//////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
//////////////////////////////////////////////////////////////////////////////
+ (id)roomWithJID:(XMPPJID *)aJID service:(XMPPService *)aService
{
	XMPPRoom *room = [[self roomsForService:aService] objectForKey:aJID];
	if (room == nil)
	{
		room = [[[self alloc] initWithJID:aJID service:aService] autorelease];
		[self addRoom:room];
	}
	return room;
}

+ (NSMutableDictionary *)roomsForService:(XMPPService *)aService
{
	NSString *key = [aService uniqueIdentifier];
	NSMutableDictionary *dict = [[self roomsForServices] objectForKey:key];
	if (dict == nil)
	{
		// Don't retain values in JID->Room dictionary
		CFDictionaryValueCallBacks callBacks = kCFTypeDictionaryValueCallBacks;
		callBacks.retain = NULL;
		callBacks.release = NULL;
		dict = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &callBacks);
		[[self roomsForServices] setObject:dict forKey:key];
		[dict autorelease];
	}
	return dict;
}

+ (void)addRoom:(XMPPRoom *)aRoom
{
	[[self roomsForService:aRoom.service] setObject:aRoom forKey:aRoom.jid];
}

// Service(uniqueID) => { Room(JID) => Room }
// FIXME: May be able to simplify since we have a user
+ (NSMutableDictionary *)roomsForServices
{
	static NSMutableDictionary *roomsForServices = nil;
	if (roomsForServices == nil)
	{
		roomsForServices = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return roomsForServices;
}

// Rooms that we've asked to join, but haven't finished joining yet.
// Someone has to hold onto them or they'll -dealloc
+ (NSMutableSet *)pendingRooms
{
	static NSMutableSet *pendingRooms = nil;
	if (pendingRooms == nil)
	{
		pendingRooms = [[NSMutableSet alloc] initWithCapacity:1];
	}
	return pendingRooms;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	NSAssert(NO, @"Do not alloc XMPPRoom. Use +roomWithJID:service:");
	return nil;
}

// Private designated initializer. Callers should use +roomWithJID:service.
- (id)initWithJID:(XMPPJID *)aJID service:(XMPPService *)aService
{
	if((self = [super init]))
	{
		self.roomUser = [XMPPUser userWithJID:aJID service:aService];
		self.nickname = aService.myJID.user;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangePresence:) name:XMPPUserDidChangePresenceNotification object:self.roomUser];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (_isJoined)
	{
		[self leave];
	}
	[[[self class] roomsForService:_roomUser.service] removeObjectForKey:_roomUser.jid];
	[_roomUser release]; _roomUser = nil;
	[_myRoomJID release]; _myRoomJID = nil;
	[super dealloc];
}

- (NSString *)displayName
{
	// FIXME: Implement
	return [NSString stringWithFormat:@"Room: %@", [self.jid fullString]];
}

- (NSString *)nickname
{
	return [self.myRoomJID resource];
}

- (void)setNickname:(NSString *)aNickname
{
	self.myRoomJID = [XMPPJID jidWithUser:[self.jid user] domain:[self.jid domain] resource:aNickname];
	if (self.isJoined)
	{
		XMPPPresenceStanza *joinPresence = [[[XMPPPresenceStanza alloc] initWithFromJID:self.service.myJID toJID:self.myRoomJID type:XMPPPresenceTypeAvailable] autorelease];
		[self.service sendStanza:joinPresence];
	}
}	

- (NSArray *)occupants
{
	return [self.occupantsForResources allValues];
}

- (NSMutableDictionary *)occupantsForResources
{
	if (_occupantsForResources == nil)
	{
		_occupantsForResources = [[NSMutableDictionary alloc] initWithCapacity:5];
	}
	return _occupantsForResources;
}

- (XMPPRoomOccupant *)myRoomOccupant
{
	for (XMPPRoomOccupant *occupant in self.occupants)
	{
		if ([[occupant name] isEqualToString:self.nickname])
		{
			return occupant;
		}
	}
	NSLog(@"WARNING: Couldn't find ourselves (%@) in the room (%@): %@", self.nickname, self.jid, self.occupants);
	return nil;
}

- (void)create
{
	[self enter];
}

- (void)enter
{
	[[[self class] pendingRooms] addObject:self];
	XMPPPresenceStanza *joinPresence = [[[XMPPPresenceStanza alloc] initWithFromJID:self.service.myJID toJID:self.myRoomJID type:XMPPPresenceTypeAvailable] autorelease];
	[joinPresence addChild:[NSXMLElement elementWithName:@"x" xmlns:XMPPMUCNamespaceName]];
	[self.service sendStanza:joinPresence];
}

- (void)leave
{
	XMPPPresenceStanza *joinPresence = [[[XMPPPresenceStanza alloc] initWithFromJID:self.service.myJID toJID:self.myRoomJID type:XMPPPresenceTypeUnavailable] autorelease];
	self.myRoomJID = nil;
	[self.service sendStanza:joinPresence];
	self.isJoined = NO;
}

- (XMPPService *)service
{
	return self.roomUser.service;
}

- (XMPPJID *)jid
{
	return self.roomUser.jid;
}

- (void)userDidChangePresence:(NSNotification *)note
{
	// FIXME: This is a complete hack. Rework room entering
	// Look for new occupants. Occupants will take care of their own removal and changes
	XMPPUser *user = [note object];
	XMPPPresenceStanza *stanza = (XMPPPresenceStanza *)[note stanza];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if ([stanza type] == XMPPPresenceTypeAvailable)
	{
		XMPPResource *resource = [user resourceForJID:stanza.fromJID];
		if ( [self.occupantsForResources objectForKey:resource.name] == nil)
		{
			XMPPRoomOccupant *occupant = [[[XMPPRoomOccupant alloc] initWithResource:resource] autorelease];
			[self.occupantsForResources setObject:occupant forKey:resource.name];
			[nc addObserver:self selector:@selector(roomOccupantDidLeaveRoom:) name:XMPPRoomOccupantDidLeaveRoomNotification object:occupant];
			[nc postNotificationName:XMPPRoomDidAddOccupantNotification object:self roomOccupant:occupant];										
		}
		if (!self.isJoined && [resource.jid isEqual:self.myRoomJID])
		{
			// We got our own presence for the first time. Maybe we've joined, maybe it's status
			// FIXME: Move this to a stanza handler
			NSUInteger statusCode = [[[[[stanza elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"]
										elementForName:@"status"] attributeForName:@"code"] stringValue] integerValue];
			if (statusCode == 201)
			{
				// We were creating it; it's still locked. We need to configure it
				XMPPRoomOwnerInfoQuery *query = [[[XMPPRoomOwnerInfoQuery alloc] initWithRoom:self] autorelease];
				[query send];
			}
			else
			{
				// iChat may still be messing with us, and our role may be 'none'
				NSString *role = [[[[stanza elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"]
								   elementForName:@"item"] attributeForName:@"role"] stringValue];
				if ([role isEqualToString:@"none"])
				{
					[self enter];
				}
				else
				{
					// FIXME: Consider other status codes
					self.isJoined = YES;
					[nc postNotificationName:XMPPRoomDidEnterNotification object:self];
					[[[self class] pendingRooms] removeObject:self];	// We'll dealloc here if no one caught us. Someone better.
				}
			}
		}
	}
}

- (void)roomOccupantDidLeaveRoom:(NSNotification *)note
{
	XMPPRoomOccupant *occupant = [note object];
	[self.occupantsForResources removeObjectForKey:occupant.name];
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPRoomDidRemoveOccupantNotification object:self roomOccupant:occupant];
}

@end
