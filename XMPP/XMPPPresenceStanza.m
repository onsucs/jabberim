#import "XMPPPresenceStanza.h"
#import "NSXMLElementAdditions.h"

@interface XMPPPresenceStanza ()
- (NSString *)stringForType:(XMPPPresenceType)atype;
- (XMPPPresenceType)typeForString:(NSString *)string;
- (XMPPPresenceShow)showForString:(NSString *)string;
- (NSString *)stringForShow:(XMPPPresenceShow)aShow;
@end

@implementation XMPPPresenceStanza

static NSString* const PresenceStanzaName = @"presence";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPPresenceStanza *)initWithFromJID:(XMPPJID *)aFromJID toJID:(XMPPJID *)aToJID type:(XMPPPresenceType)aType
{
	self = [super initWithName:PresenceStanzaName fromJID:aFromJID toJID:aToJID];
	if (self != nil)
	{
		self.type = aType;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPPresenceType)type
{
	return [self typeForString:[self typeString]];
}

- (void)setType:(XMPPPresenceType)aType
{
	[self setTypeString:[self stringForType:aType]];
}

- (NSString *)typeString
{	
	NSString *typeString = [[self attributeForName:@"type"] stringValue];
	if( [typeString length] > 0)
	{
		return typeString;
	}
	else
	{
		return [self stringForType:XMPPPresenceTypeAvailable];
	}
}

- (void)setTypeString:(NSString *)aTypeString
{
	if ([aTypeString isEqualToString:[self stringForType:XMPPPresenceTypeAvailable]])
	{
		[self removeAttributeForName:@"type"];
	}
	else
	{
		[self setStringValue:aTypeString forAttributeWithName:@"type"];
	}
}

- (XMPPPresenceShow)show
{
	return [self showForString:[self showString]];
}

- (void)setShow:(XMPPPresenceShow)aShow
{
	[self setShowString:[self stringForShow:aShow]];
}

- (NSString *)showString
{
	NSString *showString = [[self elementForName:@"show"] stringValue];
	if( [showString length] > 0)
	{
		return showString;
	}
	else
	{
		return [self stringForShow:XMPPPresenceShowAvailable];
	}
}

- (void)setShowString:(NSString *)showString
{
	[self setStringValue:showString forElementWithName:@"show"];
}

- (NSString *)statusString
{
	return [[self elementForName:@"status"] stringValue];
}

- (void)setStatusString:(NSString *)string
{
	[self setStringValue:string forElementWithName:@"status"];
}

- (XMPPPriority)priority
{
	return [[[self elementForName:@"priority"] stringValue] integerValue];
}
	
- (void)setPriority:(XMPPPriority)priority
{
	[self setStringValue:[NSString stringWithFormat:@"%d", priority] forElementWithName:@"priority"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *)stringsForTypes
{
	static NSArray *stringsForTypes = nil;
	if (stringsForTypes == nil)
	{
		// "available" isn't spec here. You can't send it; only return it to the UI.
		stringsForTypes = [[NSArray alloc] initWithObjects:@"", @"available", @"error", @"probe", @"subscribe", @"subscribed", @"unavailable", @"unsubscribe", @"unsubscribed", nil];		
	}
	return stringsForTypes;
}

- (NSString *)stringForType:(XMPPPresenceType)aType
{
	return [[self stringsForTypes] objectAtIndex:aType];
}

- (XMPPPresenceType)typeForString:(NSString *)string
{
	if ([string length] == 0)
	{
		return XMPPPresenceTypeAvailable;	// RFC 3921.5
	}
	else
	{
		NSUInteger index = [[self stringsForTypes] indexOfObject:string];
		if (index == NSNotFound)
		{
			index = XMPPPresenceTypeUnknown;
		}
		return (XMPPPresenceType)index;
	}
}

- (NSArray *)stringsForShows
{
	static NSArray *stringsForShows = nil;
	if (stringsForShows == nil)
	{
		stringsForShows = [[NSArray alloc] initWithObjects:@"", @"dnd", @"xa", @"away", @"available", @"chat", nil];
	}
	return stringsForShows;
}

- (XMPPPresenceShow)showForString:(NSString *)string
{
	if ([string length] == 0)
	{
		return XMPPPresenceShowAvailable;	// RFC 3921.2.2.2.1
	}
	else
	{
		NSUInteger index = [[self stringsForShows] indexOfObject:string];
		if (index == NSNotFound)
		{
			index = XMPPPresenceTypeUnknown;
		}
		return (XMPPPresenceType)index;
	}
}

- (NSString *)stringForShow:(XMPPPresenceShow)aShow
{
	return [[self stringsForShows] objectAtIndex:aShow];
}

@end
