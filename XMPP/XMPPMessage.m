#import "XMPPMessage.h"
#import "XMPPService.h"
#import "XMPPJID.h"

@interface XMPPMessage ()
@property (nonatomic, readwrite, assign) XMPPService *service;
@property (nonatomic, readwrite, retain) XMPPMessageStanza *stanza;
@end

@implementation XMPPMessage
@synthesize service = _service;
@synthesize stanza = _stanza;
@synthesize date = _date;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithMessageStanza:(XMPPMessageStanza *)aStanza service:(XMPPService *)aService
{
	self = [super init];
	if (self != nil)
	{
		self.service = aService;
		self.stanza = aStanza;
		NSDate *delayDate = aStanza.delayDate;
		if (delayDate != nil)
		{
			self.date = delayDate;
		}
		else
		{
			self.date = [NSDate date];
		}
	}
	return self;
}

- (id)initWithTo:(XMPPJID *)aToJID type:(XMPPMessageType)aType service:(XMPPService *)aService
{
	return [self initWithFrom:aService.myJID to:aToJID type:aType service:aService];
}

- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID type:(XMPPMessageType)aType service:(XMPPService *)aService
{
	XMPPMessageStanza *stanza =  [[[XMPPMessageStanza alloc] initWithFromJID:aFromJID toJID:aToJID type:aType] autorelease];
	return [self initWithMessageStanza:stanza service:aService];
}

- (void) dealloc
{
	_service = nil;
	[_stanza release]; _stanza = nil;
	[_date release]; _date = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Encoding, Decoding:
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
			_stanza = [[coder decodeObjectForKey:@"stanza"] copy];
		}
		else
		{
			_stanza = [[coder decodeObject] copy];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:self.stanza forKey:@"stanza"];
	}
	else
	{
		[coder encodeObject:self.stanza];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isFromMe
{
	return ([[[self fromJID] bareJID] isEqual:self.service.myJID]);
}

- (XMPPJID *)fromJID
{
	return self.stanza.fromJID;
}

- (void)setFromJID:(XMPPJID *)aJID
{
	self.stanza.fromJID = aJID;
}

- (XMPPJID *)toJID
{
	return self.stanza.toJID;
}

- (void)setToJID:(XMPPJID *)aJID
{
	self.stanza.toJID = aJID;
}

- (NSString *)body
{
	return self.stanza.body;
}

- (void)setBody:(NSString *)body
{
	self.stanza.body = body;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)send
{
	self.date = [NSDate date];
	[self.service sendStanza:self.stanza];
}
@end
