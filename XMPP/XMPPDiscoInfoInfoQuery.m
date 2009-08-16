#import "XMPPDiscoInfoInfoQuery.h"
#import "XMPPInfoQuery+Protected.h"
#import "XMPPDiscoInfoIdentityElement.h"
#import "XMPPDiscoInfoFeatureElement.h"

static NSString* const kDiscoInfoNamespaceName = @"http://jabber.org/protocol/disco#info";

@implementation XMPPDiscoInfoInfoQuery

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)stanzaHasDiscoInfoIQ:(XMPPStanza *)aStanza
{
	return [aStanza elementForName:@"query" xmlns:kDiscoInfoNamespaceName] != nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid service:(XMPPService *)service
{
	self = [super initWithType:type to:jid service:service];
	if (self != nil)
	{
		[self.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:kDiscoInfoNamespaceName]];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)node
{
	return [[self.query attributeForName:@"node"] stringValue];
}

- (void)setNode:(NSString *)node
{
	[self.query setStringValue:node forAttributeWithName:@"node"];
}

- (NSSet *)identities
{
	return [self objectsOfClass:[XMPPDiscoInfoIdentityElement class] forName:@"identity"];
}

- (void)setIdentities:(id <NSFastEnumeration>)someIdentities
{
	[self.stanza removeElementsForName:@"identity"];
	for (XMPPDiscoInfoIdentityElement *identity in someIdentities)
	{
		[self.stanza addChild:identity.xmlElement];
	}
}

- (NSSet *)features
{
	return [self objectsOfClass:[XMPPDiscoInfoFeatureElement class] forName:@"feature"];
}

- (void)setFeatures:(id <NSFastEnumeration>)someFeatures
{
	[self.stanza removeElementsForName:@"feature"];
	for (XMPPDiscoInfoIdentityElement *feature in someFeatures)
	{
		[self.stanza addChild:feature.xmlElement];
	}
}

- (BOOL)hasFeatureWithName:(NSString *)aFeatureName
{
	for (XMPPDiscoInfoFeatureElement *feature in self.features)
	{
		if ([feature.name isEqualToString:aFeatureName])
		{
			return YES;
		}
	}
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Protected methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSXMLElement *)query
{
	return [self.stanza elementForName:@"query" xmlns:kDiscoInfoNamespaceName];
}

@end
