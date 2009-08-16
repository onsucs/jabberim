#import "XMPPDiscoInfoIdentityElement.h"
#import "NSXMLElementAdditions.h"

@implementation XMPPDiscoInfoIdentityElement

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCategory:(NSString *)category name:(NSString *)name type:(NSString *)type
{
	self = [super initWithXMLElement:[NSXMLElement elementWithName:@"identity"]];
	if (self != nil)
	{
		self.category = category;
		self.name = name;
		self.type = type;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)category
{
	return [[self.xmlElement attributeForName:@"category"] stringValue];
}

- (void)setCategory:(NSString *)aCategory
{
	[self.xmlElement setStringValue:aCategory forAttributeWithName:@"category"];
}

- (NSString *)name
{
	return [[self.xmlElement attributeForName:@"name"] stringValue];
}

- (void)setName:(NSString *)aName
{
	[self.xmlElement setStringValue:aName forAttributeWithName:@"name"];
}

- (NSString *)type
{
	return [[self.xmlElement attributeForName:@"type"] stringValue];
}

- (void)setType:(NSString *)aType
{
	[self.xmlElement setStringValue:aType forAttributeWithName:@"type"];
}

@end
