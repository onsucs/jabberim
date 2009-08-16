#import "XMPPIQStanza.h"
#import "NSXMLElementAdditions.h"

@interface XMPPIQStanza ()
- (NSString *)stringForType:(XMPPIQType)aType;
- (XMPPIQType)typeForString:(NSString *)string;
@end

static NSString* const IQStanzaName = @"iq";

@implementation XMPPIQStanza

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFromJID:(XMPPJID *)aFromJID toJID:(XMPPJID *)aToJID type:(XMPPIQType)aType
{
	self = [super initWithName:IQStanzaName fromJID:aFromJID toJID:aToJID];
	if (self != nil)
	{
		NSString *typeString = [self stringForType:aType];
		if ([typeString length] > 0)
		{
			[self addAttributeWithName:@"type" stringValue:typeString];
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPIQType)type
{
	return [self typeForString:[self typeString]];
}

- (void)setType:(XMPPIQType)type
{
	[self setTypeString:[self stringForType:type]];
}

- (NSString *)typeString
{	
	return [[self attributeForName:@"type"] stringValue];
}

- (void)setTypeString:(NSString *)string
{
	[self setStringValue:string forAttributeWithName:@"type"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)stringsForTypes
{
	static NSArray *stringsForTypes = nil;
	if (stringsForTypes == nil)
	{
		stringsForTypes = [[NSArray alloc] initWithObjects:@"", @"error", @"get", @"result", @"set", nil];
	}
	return stringsForTypes;
}

- (NSString *)stringForType:(XMPPIQType)aType
{
	return [[self stringsForTypes] objectAtIndex:aType];
}

- (XMPPIQType)typeForString:(NSString *)string
{
	NSUInteger index = [[self stringsForTypes] indexOfObject:string];
	if (index == NSNotFound)
	{
		index = XMPPIQTypeUnknown;
	}
	return (XMPPIQType)index;
}

@end
