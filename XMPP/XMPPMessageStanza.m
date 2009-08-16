#import "XMPPMessageStanza.h"
#import "XMPPJID.h"
#import "NSXMLElementAdditions.h"

@interface XMPPMessageStanza ()
- (XMPPMessageType)typeForString:(NSString *)string;
- (NSString *)stringForType:(XMPPMessageType)atype;
- (NSString *)stringForChatState:(XMPPChatState)chatState;
- (NSArray *)chatStateStrings;
@end

static NSString* const MessageStanzaName = @"message";
static NSString* const ChatstatesNamespaceName = @"http://jabber.org/protocol/chatstates";

@implementation XMPPMessageStanza

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPMessageStanza *)initWithFromJID:(XMPPJID *)aFromJID toJID:(XMPPJID *)aToJID type:(XMPPMessageType)aType
{
	self = [super initWithName:MessageStanzaName fromJID:aFromJID toJID:aToJID];
	if (self != nil)
	{
		self.type = aType;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPMessageType)type
{
	return [self typeForString:[self typeString]];
}

- (void)setType:(XMPPMessageType)aType
{
	[self setStringValue:[self stringForType:aType] forAttributeWithName:@"type"];
}

- (NSString *)typeString
{
	return [[self attributeForName:@"type"] stringValue];
}

- (NSString *)subject
{
	return [[self elementForName:@"subject"] stringValue];
}

- (void)setSubject:(NSString *)subject
{
	[self setStringValue:subject forElementWithName:@"subject"];
}

- (NSString *)body
{
	return [[self elementForName:@"body"] stringValue];
}

- (void)setBody:(NSString *)body
{
	[self setStringValue:body forElementWithName:@"body"];
}

- (NSString *)thread
{
	return [[self elementForName:@"thread"] stringValue];
}

- (void)setThread:(NSString *)thread
{
	[self setStringValue:thread forElementWithName:@"thread"];
}

- (XMPPChatState)chatState
{
	NSUInteger i = 0;
	for (NSString *string in [self chatStateStrings])
	{
		if ([string length] > 0 && [self elementForName:string xmlns:ChatstatesNamespaceName] != nil)
		{
			return i;
		}
		i++;
	}
	return XMPPChatStateUnknown;
}

- (void)setChatState:(XMPPChatState)chatState
{
	for (NSString *string in [self chatStateStrings])
	{
		if ([string length] > 0)
		{
			[self removeElementsForName:string];
		}
	}
	[self addChild:[NSXMLElement elementWithName:[self stringForChatState:chatState] xmlns:ChatstatesNamespaceName]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)stringsForTypes
{
	static NSArray *stringsForTypes = nil;
	if (stringsForTypes == nil)
	{
		stringsForTypes = [[NSArray alloc] initWithObjects:@"", @"chat", @"error", @"groupchat", @"headline", @"normal", nil];
	}
	return stringsForTypes;
}

- (NSString *)stringForType:(XMPPMessageType)aType
{
	return [[self stringsForTypes] objectAtIndex:aType];
}

- (XMPPMessageType)typeForString:(NSString *)string
{
	if ([string length] == 0)
	{
		return XMPPMessageTypeNormal;	// RFC 3921 2.1.1
	}
	else
	{
		NSUInteger index = [[self stringsForTypes] indexOfObject:string];
		if (index == NSNotFound)
		{
			index = XMPPMessageTypeUnknown;
		}
		return (XMPPMessageType)index;
	}
}

- (NSArray *)chatStateStrings
{
	static NSArray *chatStateStrings = nil;
	if (chatStateStrings == nil)
	{
		chatStateStrings = [[NSArray alloc] initWithObjects:@"", @"active", @"composing", @"paused", @"inactive", @"gone", nil];
	}
	return chatStateStrings;
}

- (NSString *)stringForChatState:(XMPPChatState)chatState
{
	return [[self chatStateStrings] objectAtIndex:chatState];
}

@end
