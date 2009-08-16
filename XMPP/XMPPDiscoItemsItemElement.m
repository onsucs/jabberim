#import "XMPPDiscoItemsItemElement.h"
#import "NSXMLElementAdditions.h"
#import "XMPPJID.h"

@implementation XMPPDiscoItemsItemElement

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPJID *)jid
{
	return [XMPPJID jidWithString:[[self.xmlElement attributeForName:@"jid"] stringValue]];
}

- (void)setJID:(XMPPJID *)jid
{
	[self.xmlElement setStringValue:[jid fullString] forAttributeWithName:@"jid"];
}

- (NSString *)node
{
	return [[self.xmlElement attributeForName:@"node"] stringValue];
}

- (void)setNode:(NSString *)aNode
{
	[self.xmlElement setStringValue:aNode forAttributeWithName:@"node"];
}

- (NSString *)name
{
	return [[self.xmlElement attributeForName:@"name"] stringValue];
}

- (void)setName:(NSString *)aName
{
	[self.xmlElement setStringValue:aName forAttributeWithName:@"name"];
}

@end
