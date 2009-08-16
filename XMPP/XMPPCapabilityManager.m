#import "XMPPCapabilityManager.h"
#import "XMPPChatService.h"
#import "XMPPCapabilitiesElement.h"
#import "XMPPDiscoInfoInfoQuery.h"
#import "XMPPUserManager.h"
#import "XMPPUser.h"
#import "XMPPResource.h"
#import "XMPPDiscoInfoIdentityElement.h"
#import "XMPPDiscoInfoFeatureElement.h"

@interface XMPPCapabilityManager ()
@property (nonatomic, readonly) NSMutableDictionary *infoForNode;
@property (nonatomic, readonly) NSMutableSet *queries;
@property (nonatomic, readonly) NSMutableSet *myIdentities;
@property (nonatomic, readonly) NSMutableSet *myFeatures;
- (void)serviceDidReceivePresenceStanza:(NSNotification *)note;
- (void)serviceDidReceiveIQStanza:(NSNotification *)note;
@end

@implementation XMPPCapabilityManager
@synthesize infoForNode = _infoForNode;

+ (XMPPCapabilityManager *)sharedManager
{
	static XMPPCapabilityManager* sharedManager = nil;
	if (sharedManager == nil)
	{
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		[self.myIdentities addObject:[[[XMPPDiscoInfoIdentityElement alloc] initWithCategory:@"client" name:@"xmppframework" type:@"pc"] autorelease]];
		
		[self addFeature:@"http://jabber.org/protocol/disco#info"];		// XEP-0030 Service Discovery
		[self addFeature:@"http://jabber.org/protocol/disco#items"];	// XEP-0030 Service Discovery
	}
	return self;
}

- (void)dealloc
{
	[_myIdentities release]; _myIdentities = nil;
	[_myFeatures release]; _myFeatures = nil;
	[_infoForNode release]; _infoForNode = nil;
	[_queries release]; _queries = nil;
	[super dealloc];
}

- (NSMutableDictionary *)infoForNode
{
	if (_infoForNode == nil)
	{
		_infoForNode = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return _infoForNode;
}

- (NSMutableSet *)queries
{
	if (_queries == nil)
	{
		_queries = [[NSMutableSet alloc] initWithCapacity:1];
	}
	return _queries;
}

- (NSMutableSet *)myIdentities
{
	if (_myIdentities == nil)
	{
		_myIdentities = [[NSMutableSet alloc] initWithCapacity:1];
	}
	return _myIdentities;
}

- (NSMutableSet *)myFeatures
{
	if (_myFeatures == nil)
	{
		_myFeatures = [[NSMutableSet alloc] initWithCapacity:3];
	}
	return _myFeatures;
}

- (void)addFeature:(NSString *)featureName
{
	[self.myFeatures addObject:[[[XMPPDiscoInfoFeatureElement alloc] initWithName:featureName] autorelease]];
}

- (void)serviceDidReceivePresenceStanza:(NSNotification *)note
{
	// Look for <c/> entries we've never seen and add them to our notes.
	XMPPPresenceStanza *presence = (XMPPPresenceStanza *)[note stanza];

	XMPPCapabilitiesElement *capabilities = [presence capabilities];
	if (capabilities != nil)	// They sent us a <c/>
	{
		if ([self.infoForNode objectForKey:capabilities.node] == nil)	// We've never seen this node, so ask for more info
		{
			XMPPDiscoInfoInfoQuery *iq = [[XMPPDiscoInfoInfoQuery alloc] initWithType:XMPPIQTypeGet to:[presence fromJID] service:[note object]];
			iq.node = [NSString stringWithFormat:@"%@#%@", capabilities.node, capabilities.verificationString];
			iq.delegate = self;
			[iq send];
			[self.queries addObject:iq];
			[iq release];
		}
	}
}

- (void)serviceDidReceiveIQStanza:(NSNotification *)note
{
	// Check if someone is asking for our capabilities
	// FIXME: We're not actually checking verificationString here.
	XMPPIQStanza *stanza = (XMPPIQStanza *)[note stanza];
	if ([stanza type] == XMPPIQTypeGet && [XMPPDiscoInfoInfoQuery stanzaHasDiscoInfoIQ:stanza])
	{
		XMPPService *service = [note object];
		XMPPDiscoInfoInfoQuery *query = [[[XMPPDiscoInfoInfoQuery alloc] initWithResultForIQStanza:stanza service:service] autorelease];
		[query setIdentities:self.myIdentities];
		[query setFeatures:self.myFeatures];
		[query send];
	}
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	// FIXME: Handle errors
	[self.queries removeObject:[note object]];
}

- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	XMPPDiscoInfoInfoQuery *iq = [[[XMPPDiscoInfoInfoQuery alloc] initWithIQStanza:(XMPPIQStanza *)[note stanza] service:[[note object] service]] autorelease];	
	if (iq.node != nil)
	{
		[self.infoForNode setObject:iq forKey:iq.node];
	}
	[self.queries removeObject:[note object]];
	
	XMPPResource *resource = [[XMPPUser userWithJID:iq.jid service:iq.service] resourceForJID:iq.jid];
	resource.info = iq;
	
	// FIXME: Need to notify someone of this change.
}

@end
