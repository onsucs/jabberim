#import "XMPPCapabilitiesElement.h"
#import "NSXMLElementAdditions.h"

NSString* const XMPPCapabilitiesNamespaceName = @"http://jabber.org/protocol/caps";

@interface XMPPCapabilitiesElement ()
- (XMPPCapabilitiesHashAlgorithm)hashAlgorithmForString:(NSString *)hashAlgorithmString;
- (NSString *)stringForHashAlgorithm:(XMPPCapabilitiesHashAlgorithm)hashAlgorithm;
@end

@implementation XMPPCapabilitiesElement

- (XMPPCapabilitiesElement *)init
{
	return [self initWithXMLElement:[NSXMLElement elementWithName:@"c" xmlns:XMPPCapabilitiesNamespaceName]];
}

- (XMPPCapabilitiesHashAlgorithm)hashAlgorithm
{
	return [self hashAlgorithmForString:[[self.xmlElement attributeForName:@"hash"] stringValue]];
}

- (void)setHashAlgorithm:(XMPPCapabilitiesHashAlgorithm)algorithm
{
	[self.xmlElement setStringValue:[self stringForHashAlgorithm:algorithm] forElementWithName:@"hash"];
}

- (NSString *)node
{
	return [[self.xmlElement attributeForName:@"node"] stringValue];
}

- (void)setNode:(NSString *)aNode
{
	[self.xmlElement setStringValue:aNode forElementWithName:@"node"];
}

- (NSString *)verificationString
{
	return [[self.xmlElement attributeForName:@"ver"] stringValue];
}

- (void)setVerificationString:(NSString *)string
{
	[self.xmlElement setStringValue:string forElementWithName:@"ver"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *)hashAlgorithmStrings
{
	static NSArray *hashAlgorithmStrings;
	if (hashAlgorithmStrings == nil)
	{
		hashAlgorithmStrings = [[NSArray alloc] initWithObjects:@"", @"sha-1", nil];
	}
	return hashAlgorithmStrings;
}

- (XMPPCapabilitiesHashAlgorithm)hashAlgorithmForString:(NSString *)hashAlgorithmString
{
	NSUInteger index = [[self hashAlgorithmStrings] indexOfObject:hashAlgorithmString];
	if (index == NSNotFound)
	{
		index = XMPPCapabilitiesHashUnknown;
	}
	return index;
}

- (NSString *)stringForHashAlgorithm:(XMPPCapabilitiesHashAlgorithm)hashAlgorithm
{
	return [[self hashAlgorithmStrings] objectAtIndex:hashAlgorithm];
}

@end

@implementation XMPPPresenceStanza (XMPPCapabilties)
- (XMPPCapabilitiesElement *)capabilities
{
	return [[[XMPPCapabilitiesElement alloc] initWithXMLElement:[self elementForName:@"c" xmlns:XMPPCapabilitiesNamespaceName]] autorelease];
}

- (void)setCapabilities:(XMPPCapabilitiesElement *)capabilities
{
	[self removeElementsForName:@"c"];
	[self addChild:capabilities.xmlElement];
}
@end