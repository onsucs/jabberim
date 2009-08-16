#import "XMPPDiscoItemsInfoQuery.h"
#import "XMPPInfoQuery+Protected.h"
#import "NSXMLElementAdditions.h"
#import "XMPPDiscoItemsItemElement.h"
#import "XMPPService.h"

static NSString* const kDiscoItemsNamespaceName = @"http://jabber.org/protocol/disco#items";

@implementation XMPPDiscoItemsInfoQuery

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid service:(XMPPService *)service
{
	self = [super initWithType:type to:jid service:service];
	if (self != nil)
	{
		XMPPIQStanza *stanza = [[[XMPPIQStanza alloc] initWithFromJID:[service myJID] toJID:nil type:type] autorelease];
		[stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:kDiscoItemsNamespaceName]];
		self.stanza = stanza;
	}
	return self;
}

- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid node:(NSString *)node service:(XMPPService *)service
{
	self = [self initWithType:type to:jid service:service];
	if (self != nil)
	{
		if ([node length] > 0)
		{
			[self.query setStringValue:node forAttributeWithName:@"node"];
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSSet *)items
{
	return [self objectsOfClass:[XMPPDiscoItemsItemElement class] forName:@"item"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Protected Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSXMLElement *)query
{
	return [self.stanza elementForName:@"query" xmlns:kDiscoItemsNamespaceName];
}

@end