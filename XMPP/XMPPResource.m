#import "XMPPResource.h"
#import "XMPPJID.h"
#import "XMPPPresenceStanza.h"

NSString* const XMPPResourceDidChangeChatStateNotification = @"XMPPResourceDidChangeChatStateNotification";
NSString* const XMPPResourceDidBecomeUnavailableNotification = @"XMPPResourceDidBecomeUnavailableNotification";

static NSString* const StanzaKey = @"stanza";
static NSString* const LastPresenceUpdateKey = @"lastPresenceUpdate";
static NSString* const InfoKey = @"info";
static NSString* const ChatStateKey = @"chatState";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface XMPPResource ()
@property (nonatomic, readwrite, retain) XMPPPresenceStanza *stanza;
@property (nonatomic, readwrite, retain) NSDate *lastPresenceUpdate;
@property (nonatomic, readwrite, assign) XMPPChatState chatState;
@end

@implementation XMPPResource
@synthesize stanza = _stanza;
@synthesize lastPresenceUpdate = _lastPresenceUpdate;
@synthesize info = _info;
@synthesize chatState = _chatState;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithPresenceStanza:(XMPPPresenceStanza *)aPresence
{
	if((self = [super init]))
	{
		[self updateWithPresenceStanza:aPresence];
		self.chatState = XMPPChatStateUnknown;
	}
	return self;
}

- (id)initWithJID:(XMPPJID *)jid
{
	return [self initWithPresenceStanza:[[[XMPPPresenceStanza alloc] initWithFromJID:jid toJID:nil type:XMPPPresenceTypeAvailable] autorelease]];
}	

- (void)dealloc
{
	[_stanza release]; _stanza = nil;
	[_lastPresenceUpdate release]; _lastPresenceUpdate = nil;
	[_info release]; _info = nil;
	[super dealloc];
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
	if((self = [super init]))
	{
		if([coder allowsKeyedCoding])
		{
			self.stanza				= [coder decodeObjectForKey:StanzaKey];
			self.lastPresenceUpdate = [coder decodeObjectForKey:LastPresenceUpdateKey];
			self.info				= [coder decodeObjectForKey:InfoKey];
			self.chatState			= [coder decodeInt32ForKey:ChatStateKey];
		}
		else
		{
			self.stanza				= [coder decodeObject];
			self.lastPresenceUpdate = [coder decodeObject];
			self.info				= [coder decodeObject];
			self.chatState			= [(NSNumber*)[coder decodeObject] shortValue];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:self.stanza				forKey:StanzaKey];
		[coder encodeObject:self.lastPresenceUpdate forKey:LastPresenceUpdateKey];
		[coder encodeObject:self.info				forKey:InfoKey];
		[coder encodeInt32:self.chatState			forKey:ChatStateKey];
	}
	else
	{
		[coder encodeObject:self.stanza];
		[coder encodeObject:self.lastPresenceUpdate];
		[coder encodeObject:self.info];
		[coder encodeObject:[NSNumber numberWithShort:self.chatState]];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)name
{
	return [self.jid resource];
}

- (XMPPJID *)jid
{
	return self.stanza.fromJID;
}

- (void)setJID:(XMPPJID *)aJID
{
	self.stanza.fromJID = aJID;
}

- (XMPPPresenceShow)show
{
	return self.stanza.show;
}

- (void)setShow:(XMPPPresenceShow)show
{
	self.stanza.show = show;
}

- (NSString *)showString
{
	return self.stanza.showString;
}

- (void)setShowString:(NSString *)string
{
	self.stanza.showString = string;
}

- (NSString *)statusString
{
	return self.stanza.statusString;
}

- (void)setStatusString:(NSString *)string
{
	self.stanza.statusString = string;
}

- (XMPPPriority)priority
{
	return self.stanza.priority;
}

- (void)setPriority:(XMPPPriority)priority
{
	self.stanza.priority = priority;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Update Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateWithPresenceStanza:(XMPPPresenceStanza *)aPresence
{
	self.stanza = aPresence;
	self.lastPresenceUpdate = [NSDate date];
}

- (void)updateWithMessageStanza:(XMPPMessageStanza *)aMessage
{
	XMPPChatState chatState = [aMessage chatState];
	if (self.chatState != chatState)
	{
		self.chatState = chatState;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPResourceDidChangeChatStateNotification object:self];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Comparison Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSComparisonResult)compare:(XMPPResource *)another
{
	XMPPPriority mp = self.priority;
	XMPPPriority ap = another.priority;
	
	if(mp < ap)
	{
		return NSOrderedDescending;
	}
	if(mp > ap)
	{
		return NSOrderedAscending;
	}
	
	// Priority is the same.
	// Determine who is more available based on their show.
	XMPPPresenceShow ms = self.show;
	XMPPPresenceShow as = another.show;
	
	if(ms < as)
	{
		return NSOrderedDescending;
	}
	if(ms > as)
	{
		return NSOrderedAscending;
	}
	
	// Priority and Show are the same.
	// Determine based on who was the last to receive a presence element.
	NSDate *mr = [self lastPresenceUpdate];
	NSDate *ar = [another lastPresenceUpdate];
	
	return [mr compare:ar];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)hash
{
	return [self.jid hash];
}

- (BOOL)isEqual:(id)anObject
{
	if([anObject isMemberOfClass:[self class]])
	{
		XMPPResource *another = (XMPPResource *)anObject;
		
		return [self.jid isEqual:[another jid]];
	}
	
	return NO;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"XMPPResource: %@", [self.jid fullString]];
}

@end
