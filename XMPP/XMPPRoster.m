//  XMPPRoster.m

// FIXME: Not handling user unsubscriptions correctly

#import "XMPPRoster.h"
#import "XMPPJID.h"
#import "XMPPUser.h"
#import "XMPPService.h"
#import "XMPPRosterInfoQuery.h"
#import "XMPPRosterItemElement.h"
#import "XMPPDiscoInfoInfoQuery.h"

NSString* const XMPPRosterDidAddUsersNotification = @"XMPPRosterDidAddUsersNotification";
NSString* const XMPPRosterDidRemoveUsersNotification = @"XMPPRosterDidRemoveUsersNotification";

//
// Private methods
//
@interface XMPPRoster ()
@property (nonatomic, readwrite, assign) XMPPService *service;
@property (nonatomic, readonly) NSMutableDictionary *usersForJID;
@property (nonatomic, readonly) NSMutableSet *requests;
- (void)serviceDidReceiveIQStanza:(NSNotification *)note;
- (void)addUsersFromQuery:(XMPPRosterInfoQuery *)query;
@end

//
// Implementation
//
@implementation XMPPRoster
@synthesize service = _service;
@synthesize usersForJID = _usersForJID;
@synthesize requests = _requests;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (XMPPRoster *)rosterWithService:(XMPPService *)service
{
	return [[[self alloc] initWithService:service] autorelease];
}

- (XMPPRoster *)initWithService:(XMPPService *)aService
{
	self = [super init];
	if (self != nil)
	{
		self.service = aService;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceDidReceiveIQStanza:) name:XMPPServiceDidReceiveIQStanzaNotification object:aService];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_usersForJID release]; _usersForJID = nil;
	_service = nil;	// Not retained
	[_requests release]; _requests = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSSet *)users
{
	return [NSSet setWithArray:[self.usersForJID allValues]];
}

- (NSUInteger)count
{
	return [self.usersForJID count];
}

- (NSMutableDictionary *)usersForJID
{
	if (_usersForJID == nil)
	{
		_usersForJID = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
    return _usersForJID; 
}

- (NSMutableSet *)requests
{
	if (_requests == nil)
	{
		_requests = [[NSMutableSet alloc] initWithCapacity:1];
	}
	return _requests;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)requestUpdate
{
	XMPPInfoQuery *request = [[[XMPPRosterInfoQuery alloc] initWithType:XMPPIQTypeGet service:self.service] autorelease];
	[request setDelegate:self];
	[request send];
	[[self requests] addObject:request];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	[self addUsersFromQuery:[note object]];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	// FIXME: Implement
}

- (void)serviceDidReceiveIQStanza:(NSNotification *)note
{
	XMPPIQStanza *stanza = (XMPPIQStanza *)[note stanza];
	if ([stanza type] == XMPPIQTypeSet && [XMPPRosterInfoQuery stanzaHasRosterIQ:stanza])
	{
		XMPPRosterInfoQuery *query = [[[XMPPRosterInfoQuery alloc] initWithIQStanza:stanza service:self.service] autorelease];
		[self addUsersFromQuery:query];
	}	
}

- (void)addUsersFromQuery:(XMPPRosterInfoQuery *)query
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSMutableSet *addedUsers = [NSMutableSet set];
	NSMutableSet *removedUsers = [NSMutableSet set];
	
	for (XMPPRosterItemElement *item in [query items])
	{
		XMPPJID *jid = [item jid];
		
		if([item subscription] == XMPPSubscriptionRemove)
		{
			XMPPUser *user = [[self usersForJID] objectForKey:jid];
			if (user != nil)
			{
				[removedUsers addObject:user];
				[[self usersForJID] removeObjectForKey:jid];
			}
		}
		else
		{
			XMPPUser *user = [[self usersForJID] objectForKey:jid];
			if(user != nil)
			{
				[user updateWithRosterItem:item];
			}
			else
			{
				XMPPUser *newUser = [XMPPUser userWithRosterItem:item service:[self service]];
				[[self usersForJID] setObject:newUser forKey:jid];
				[addedUsers addObject:newUser];
			}
		}
	}
	
	if ([addedUsers count] > 0)
	{
		[nc postNotificationName:XMPPRosterDidAddUsersNotification object:self users:addedUsers];
	}
	if ([removedUsers count] > 0)
	{
		[nc postNotificationName:XMPPRosterDidRemoveUsersNotification object:self users:removedUsers]; //Boy this was a bug. It took me 4 hours to find out that the author of the Framework accidently wrote addedUsers instead of removedUsers. IT CAN'T WORK X(...
	}
}

@end
