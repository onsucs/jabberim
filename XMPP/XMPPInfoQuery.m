#import "XMPPInfoQuery+Protected.h"
#import "NSXMLElementAdditions.h"
#import "XMPPService.h"
#import "NSNotificationCenter+RNDelegate.h"
#import "XMPPResource.h"

NSString* const XMPPInfoQueryDidReceiveResultNotification = @"XMPPInfoQueryDidReceiveResultNotification";
NSString* const XMPPInfoQueryDidReceiveErrorNotification = @"XMPPInfoQueryDidReceiveErrorNotification";

static NSString* const StanzaKey = @"stanza";

//
// Private methods
//
@interface XMPPInfoQuery ()
- (void)serviceDidReceiveIQStanza:(NSNotification *)note;
- (void)serviceDidFailSendStanza:(NSNotification *)note;
@end

//
// Implementation
//
@implementation XMPPInfoQuery
@synthesize delegate = _delegate;
@synthesize service = _service;
@synthesize stanza = _stanza;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSSet *)notificationNames
{
	static NSSet *notificationNames = nil;
	if (notificationNames == nil)
	{
		notificationNames = [[NSSet alloc] initWithObjects:
							 XMPPInfoQueryDidReceiveErrorNotification,
							 XMPPInfoQueryDidReceiveResultNotification,
							 nil];
	}
	return notificationNames;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid service:(XMPPService *)service
{
	return [self initWithIQStanza:[[[XMPPIQStanza alloc] initWithFromJID:service.myJID toJID:jid type:type] autorelease]
						  service:service];
}

- (id)initWithIQStanza:(XMPPIQStanza *)stanza service:(XMPPService *)service
{
	self = [super init];
	if (self != nil)
	{
		self.service = service;
		self.stanza = stanza;
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(serviceDidReceiveIQStanza:) name:XMPPServiceDidReceiveIQStanzaNotification object:service];
		[nc addObserver:self selector:@selector(serviceDidFailSendStanza:) name:XMPPServiceDidFailSendStanzaNotification object:service];
	}
	return self;
}

- (id)initWithResultForIQStanza:(XMPPIQStanza *)aStanza service:(XMPPService *)service;
{
	self = [self initWithIQStanza:aStanza service:service];
	if (self != nil)
	{
		self.type = XMPPIQTypeResult;
		self.stanza.toJID = self.stanza.fromJID;
		self.stanza.fromJID = self.service.myJID;
	}
	return self;
}

- (void) dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	[nc removeObserver:_delegate name:nil object:self];
	_delegate = nil;

	[_service release]; _service = nil;
	[_stanza release]; _stanza = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Encoding, Decoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NOTE: XMPPInfoQuery:s don't encode their XMPPService. The decoder needs to wire one up for them.

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
			self.stanza	= [coder decodeObjectForKey:StanzaKey];
		}
		else
		{
			self.stanza	= [coder decodeObject];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:self.stanza	forKey:StanzaKey];
	}
	else
	{
		[coder encodeObject:self.stanza];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setDelegate:(id)delegate
{
	if (_delegate != delegate)
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		if (_delegate != nil)
		{
			[nc removeObserver:_delegate name:nil object:self];
		}
		
		_delegate = delegate;
		
		if (_delegate != nil)
		{
			[nc addObserver:_delegate forRespondingNotificationNames:[[self class] notificationNames] prefix:@"XMPP" object:self];
		}
	}
}		

- (XMPPJID *)jid
{
	if (self.stanza.type == XMPPIQTypeResult)
	{
		return self.stanza.fromJID;
	}
	else
	{
		return self.stanza.toJID;
	}
}

- (XMPPIQType)type
{
	return self.stanza.type;
}

- (void)setType:(XMPPIQType)aType
{
	self.stanza.type = aType;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)send
{
	[[self service] sendStanza:[self stanza]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPService callbacks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)serviceDidReceiveIQStanza:(NSNotification *)note
{
	XMPPIQStanza *stanza = (XMPPIQStanza *)[note stanza];
	if ([[stanza uniqueIdentifier] isEqual:[[self stanza] uniqueIdentifier]])
	{
		self.stanza = stanza;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPInfoQueryDidReceiveResultNotification object:self userInfo:[note userInfo]];
	}
}

- (void)serviceDidFailSendStanza:(NSNotification *)note
{
	// FIXME: Implement
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Protected Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This isn't part of an infoquery, but it's very common, and subclasses use it.
- (NSXMLElement *)query
{
	return [self.stanza elementForName:@"query"];
}

- (NSSet *)objectsOfClass:(Class)class forName:(NSString *)name
{
	NSMutableSet *objects = [NSMutableSet set];
	for (NSXMLElement *element in [[self query] elementsForName:name])
	{
		id object = [[class alloc] initWithXMLElement:element];
		[objects addObject:object];
		[object release];
	}
	return objects;
}
@end
