#import "XMPPStanza.h"
#import "XMPPJID.h"
#import "NSXMLElementAdditions.h"
#import "XMPPMessageStanza.h"
#import "XMPPPresenceStanza.h"
#import "XMPPIQStanza.h"
#import "NSDate+XMPPExtensions.h"

NSString* const XMPPStanzaKey = @"stanza";

@interface XMPPStanza ()
- (void)generateUniqueIdentifier;
@end

@implementation XMPPStanza

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithName:(NSString *)name fromJID:(XMPPJID *)from toJID:(XMPPJID *)to 
{
	self = [super initWithName:name];
	if (self != nil)
	{
		[self generateUniqueIdentifier];
		if (to != nil)
		{
			[self addAttributeWithName:@"to" stringValue:[to fullString]];
		}
		if (from != nil)
		{
			[self addAttributeWithName:@"from" stringValue:[from fullString]];
		}
	}
	return self;
}

- (id)initWithXMLElement:(NSXMLElement *)element
{
	self = [super initWithName:[element name]];
	if (self != nil)
	{
		for (NSXMLNode *namespace in [element namespaces])
		{
			NSXMLNode *namespaceCopy = [namespace copy];
			[self addNamespace:namespaceCopy];
			[namespaceCopy release];
		}
		for (NSXMLNode *attribute in [element attributes])
		{
			NSXMLNode *attributeCopy = [attribute copy];
			[self addAttribute:attributeCopy];
			[attributeCopy release];
		}
		for (NSXMLNode *child in [element children])
		{
			NSXMLNode *childCopy = [child copy];
			[self addChild:childCopy];
			[childCopy release];
		}
	}
	return self;	
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] alloc] initWithXMLElement:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Encoding, Decoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if ! TARGET_OS_IPHONE
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
	if([encoder isBycopy])
		return self;
	else
		return [NSDistantObject proxyWithLocal:self connection:[encoder connection]];
}
#endif

- (id)initWithCoder:(NSCoder *)coder
{
	NSString *xmlString;
	if([coder allowsKeyedCoding])
	{
		xmlString = [coder decodeObjectForKey:@"xmlString"];
	}
	else
	{
		xmlString = [coder decodeObject];
	}
	NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:xmlString error:nil];
	return [self initWithXMLElement:element];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	NSString *xmlString = [self XMLString];
	
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:xmlString forKey:@"xmlString"];
	}
	else
	{
		[coder encodeObject:xmlString];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)uniqueIdentifier
{
	return [[self attributeForName:@"id"] stringValue];
}

- (void)setUniqueIdentifier:(NSString *)string
{
	[self setStringValue:string forAttributeWithName:@"id"];
}

- (XMPPJID *)toJID
{
	return [XMPPJID jidWithString:[[self attributeForName:@"to"] stringValue]];
}

- (void)setToJID:(XMPPJID *)jid
{
	[self setStringValue:[jid fullString] forAttributeWithName:@"to"];
}

- (XMPPJID *)fromJID
{
	return [XMPPJID jidWithString:[[self attributeForName:@"from"] stringValue]];
}

- (void)setFromJID:(XMPPJID *)jid
{
	[self setStringValue:[jid fullString] forAttributeWithName:@"from"];
}

- (NSString *)language
{
	return [[self attributeForName:@"xml:lang"] stringValue];
}

- (void)setLanguage:(NSString *)string
{
	[self setStringValue:string forAttributeWithName:@"xml:lang"];
}

- (NSDate *)delayDate
{
	NSString *stampString =	[[[self elementForName:@"delay" xmlns:@"urn:xmpp:delay"]
							 attributeForName:@"stamp"] stringValue];
	if (stampString == nil)
	{
		return nil;
	}
	else
	{
		return [NSDate dateWithXMPPDateString:stampString];
	}
}

- (void)setDelayDate:(NSDate *)stamp
{
	[self removeElementsForName:@"delay"];
	NSXMLElement *delayStamp = [NSXMLElement elementWithName:@"delay" xmlns:@"urn:xmpp:delay"];
	[delayStamp addAttributeWithName:@"stamp" stringValue:[stamp xmppDateString]];
	[self addChild:delayStamp];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)generateUniqueIdentifier
{
	static NSString *lastUniqueID = @"0";	// Using an object so we can @synchronized(). Maybe there's an easier way?
	@synchronized(lastUniqueID)
	{
		[lastUniqueID release];
		lastUniqueID = [[NSString alloc] initWithFormat:@"%d", [lastUniqueID intValue] + 1];
	}
	self.uniqueIdentifier = lastUniqueID;
}

@end

@implementation NSNotification (XMPPStanza)
- (XMPPStanza *)stanza
{
	return [[self userInfo] objectForKey:XMPPStanzaKey];
}
@end

@implementation NSNotificationCenter (XMPPStanza)
- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender stanza:(XMPPStanza *)stanza
{
	[self postNotificationName:notificationName object:notificationSender userInfo:[NSDictionary dictionaryWithObject:stanza forKey:XMPPStanzaKey]];
}
@end

@implementation NSNotificationQueue (XMPPStanza)
- (void)enqueueNotificationName:(NSString *)notificationName object:(id)notificationSender stanza:(XMPPStanza *)stanza
{
	NSNotification *note = [NSNotification notificationWithName:notificationName object:notificationSender userInfo:[NSDictionary dictionaryWithObject:stanza forKey:XMPPStanzaKey]];
	[[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:nil];
}
@end

