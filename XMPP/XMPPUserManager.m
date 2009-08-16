#import "XMPPUserManager.h"
#import "XMPPUser.h"
#import "XMPPService.h"
#import "XMPPJID.h"

//
// Friend methods
//
@interface XMPPUser (XMPPUserManager)
- (XMPPUser *)initWithJID:(XMPPJID *)aJID service:(XMPPService *)aService;
@end

//
// Private methods
//
@interface XMPPUserManager ()
@property (nonatomic, readonly, retain) NSMutableDictionary *users;
- (NSMutableDictionary *)usersForService:(XMPPService *)aService;
- (void)addUser:(XMPPUser *)aUser;
- (id)keyForJID:(XMPPJID *)aJID;
@end

//
// Implementation
//
@implementation XMPPUserManager

+ (XMPPUserManager *)sharedManager
{
	static XMPPUserManager* sharedManager = nil;
	if (sharedManager == nil)
	{
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (NSMutableDictionary *)users
{
	if (_users == nil)
	{
		_users = [[NSMutableDictionary alloc] initWithCapacity:1];	// Services dictionary
	}
	return _users;
}

- (void) dealloc
{
	[_users release]; _users = nil;
	
	[super dealloc];
}

- (XMPPUser *)userForJID:(XMPPJID *)aJID service:(XMPPService *)aService
{
	NSAssert(aJID != nil, @"userForJID called with nil JID.");
	NSAssert(aService != nil, @"userForJID called with nil Service.");
	XMPPUser *user = [[self usersForService:aService] objectForKey:[self keyForJID:aJID]];
	if (user == nil)
	{
		user = [[[XMPPUser alloc] initWithJID:aJID service:aService] autorelease];	// Don't use the convience constructor; it calls us.
		[self addUser:user];
	}
	return user;
}

- (NSMutableDictionary *)usersForService:(XMPPService *)aService
{
	NSString *key = [aService uniqueIdentifier];
	NSMutableDictionary *dict = [self.users objectForKey:key];
	if (dict == nil)
	{
		// FIXME: See note in .h about switching between strong and weak references
//		// Don't retain values in JID->User dictionary
//		CFDictionaryValueCallBacks callBacks = kCFTypeDictionaryValueCallBacks;
//		callBacks.retain = NULL;
//		callBacks.release = NULL;
//		dict = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &callBacks);
//		[dict autorelease];
		
		dict = [NSMutableDictionary dictionaryWithCapacity:10];
		[self.users setObject:dict forKey:key];
	}
	return dict;
}

- (id)keyForJID:(XMPPJID *)aJID
{
	return [aJID bareJID];
}

- (void)addUser:(XMPPUser *)aUser
{
	[[self usersForService:[aUser service]] setObject:aUser forKey:[self keyForJID:[aUser jid]]];
}

- (void)removeUser:(XMPPUser *)aUser
{
	[[self usersForService:[aUser service]] removeObjectForKey:[self keyForJID:[aUser jid]]];
}

// Service delegate methods

- (void)serviceDidReceivePresenceStanza:(NSNotification *)note
{
	XMPPPresenceStanza *stanza = (XMPPPresenceStanza *)[note stanza];
	if (stanza.type == XMPPPresenceTypeAvailable ||
		stanza.type == XMPPPresenceTypeUnavailable)
	{
		XMPPUser *user = [self userForJID:[stanza.fromJID bareJID] service:[note object]];
		[user updateWithPresenceStanza:stanza];
	}
}

- (void)serviceDidReceiveMessageStanza:(NSNotification *)note
{
	// Manage user-information stored in <message>s, such as chatstate
	XMPPMessageStanza *stanza = (XMPPMessageStanza *)[note stanza];
	XMPPUser *user = [self userForJID:[stanza.fromJID bareJID] service:[note object]];
	[user updateWithMessageStanza:stanza];
}

@end
