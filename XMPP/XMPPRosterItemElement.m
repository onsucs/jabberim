#import "XMPPRosterItemElement.h"
#import "XMPPJID.h"
#import "NSXMLElementAdditions.h"

//
// Private methods
//
@interface XMPPRosterItemElement ()
@property (nonatomic, readwrite, retain, setter=setJID:) XMPPJID *jid;
- (XMPPSubscription)subscriptionForString:(NSString *)subscriptionString;
- (NSString *)stringForSubscription:(XMPPSubscription)subscription;
@end

//
// Implementation
//
@implementation XMPPRosterItemElement

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPRosterItemElement *)init
{
	return [self initWithXMLElement:[NSXMLElement elementWithName:@"item"]];
}

- (XMPPRosterItemElement *)initWithJID:(XMPPJID *)aJID
{
	self = [self init];
	if (self != nil)
	{
		self.jid = aJID;
	}
	return self;
}	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPJID *)jid
{
	return [XMPPJID jidWithString:[[self.xmlElement attributeForName:@"jid"] stringValue]];
}

- (void)setJID:(XMPPJID *)aJID
{
	[self.xmlElement setStringValue:[aJID fullString] forAttributeWithName:@"jid"];
}

- (NSSet *)groupNames
{
	NSMutableSet *groupNames = [NSMutableSet set];
	for (NSXMLElement *element in [self.xmlElement elementsForName:@"group"])
	{
		[groupNames addObject:[element stringValue]];
	}
	return groupNames;
}

- (void)setGroupNames:(NSSet *)names
{
	[self.xmlElement removeElementsForName:@"group"];
	for (NSString *name in names)
	{
		[self.xmlElement addChild:[NSXMLElement elementWithName:@"group" stringValue:name]];
	}
}

- (BOOL)isPendingApproval
{
	return [[[self.xmlElement attributeForName:@"ask"] stringValue] isEqualToString:@"subscribe"];
}

- (void)setIsPendingApproval:(BOOL)flag
{
	if (flag)
	{
		[self.xmlElement setStringValue:@"subscribe" forAttributeWithName:@"ask"];
	}
	else
	{
		[self.xmlElement removeAttributeForName:@"ask"];
	}
}

- (NSString *)nickname
{
	return [[self.xmlElement attributeForName:@"name"] stringValue];
}

- (void)setNickname:(NSString *)name
{
	[self.xmlElement setStringValue:name forAttributeWithName:@"name"];
}

- (XMPPSubscription)subscription
{
	return [self subscriptionForString:[[self.xmlElement attributeForName:@"subscription"] stringValue]];
}

- (void)setSubscription:(XMPPSubscription)subscription
{
	[self.xmlElement setStringValue:[self stringForSubscription:subscription] forAttributeWithName:@"subscription"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *)subscriptionStrings
{
	static NSArray *subscriptionStrings;
	if (subscriptionStrings == nil)
	{
		subscriptionStrings = [[NSArray alloc] initWithObjects:@"", @"none", @"to", @"from", @"both", @"remove", nil];
	}
	return subscriptionStrings;
}

- (XMPPSubscription)subscriptionForString:(NSString *)subscriptionString
{
	NSUInteger index = [[self subscriptionStrings] indexOfObject:subscriptionString];
	if (index == NSNotFound)
	{
		index = XMPPSubscriptionUnknown;
	}
	return index;
}

- (NSString *)stringForSubscription:(XMPPSubscription)subscription
{
	return [[self subscriptionStrings] objectAtIndex:subscription];
}

@end
