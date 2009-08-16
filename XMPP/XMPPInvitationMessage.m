#import "XMPPInvitationMessage.h"
#import "XMPPMessageStanza.h"
#import "XMPPService.h"
#import "XMPPJID.h"
#import "XMPPRoom.h"

static NSString* const InvitationMessageKey = @"invitationMessage";
static NSString* const MUCUserNamespaceName = @"http://jabber.org/protocol/muc#user";

@interface XMPPInvitationMessage ()
- (NSXMLElement *)inviteElement;
@end

@implementation XMPPInvitationMessage

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)stanzaHasInvitation:(XMPPMessageStanza *)aStanza
{
	return [[aStanza elementForName:@"x" xmlns:MUCUserNamespaceName] elementForName:@"invite"] != nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFromJID:(XMPPJID *)aFromJID toJID:(XMPPJID *)aToJID groupChatJID:(XMPPJID *)aGroupChat reason:(NSString *)aReason service:(XMPPService *)aService
{
	self = [super initWithFrom:aFromJID to:aGroupChat type:XMPPMessageTypeNormal service:aService];
	if (self != nil)
	{
		NSXMLElement *xElement = [NSXMLElement elementWithName:@"x" xmlns:MUCUserNamespaceName];
		NSXMLElement *inviteElement = [NSXMLElement elementWithName:@"invite"];
		[inviteElement addAttributeWithName:@"to" stringValue:[aToJID fullString]];	
		if (aReason != nil)
		{
			NSXMLElement *reasonElement = [NSXMLElement elementWithName:@"reason" stringValue:aReason];
			[inviteElement addChild:reasonElement];
		}
		[xElement addChild:inviteElement];
		[self.stanza addChild:xElement];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (XMPPRoom *)room
{
	return [XMPPRoom roomWithJID:self.stanza.fromJID service:self.service];
}

- (XMPPJID *)inviter
{
	NSString *inviterString = [[[self inviteElement] attributeForName:@"from"] stringValue];
	return [XMPPJID jidWithString:inviterString];
}

- (BOOL)hasContinue
{
	return ([[self inviteElement] elementForName:@"continue"] != nil);
}

- (void)setHasContinue:(BOOL)hasContinue
{
	if (hasContinue != self.hasContinue)
	{
		if (hasContinue)
		{
			[[self inviteElement] addChild:[NSXMLElement elementWithName:@"continue"]];
		}
		else
		{
			[[self inviteElement] removeElementsForName:@"continue"];
		}
	}
}		

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)accept
{
	[self.room enter];
}

- (void)decline
{
	[self declineWithReason:nil];
}

- (void)declineWithReason:(NSString *)aReason
{
	XMPPMessageStanza *stanza = [[[XMPPMessageStanza alloc] initWithFromJID:self.service.myJID toJID:self.stanza.fromJID type:XMPPMessageTypeNormal] autorelease];
	NSXMLElement *xElement = [NSXMLElement elementWithName:@"x" xmlns:MUCUserNamespaceName];
	NSXMLElement *declineElement = [NSXMLElement elementWithName:@"decline"];
	[declineElement addAttributeWithName:@"to" stringValue:[self.inviter fullString]];
	if ([aReason length] > 0)
	{
		[declineElement addChild:[NSXMLElement elementWithName:@"reason" stringValue:aReason]];
	}
	[xElement addChild:declineElement];
	[stanza addChild:xElement];
	[self.service sendStanza:stanza];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSXMLElement *)inviteElement
{
	return [[self.stanza elementForName:@"x" xmlns:MUCUserNamespaceName] elementForName:@"invite"];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotificationCenter Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotificationCenter (XMPPInvitationMessage)
- (void)postNotificationName:(NSString *)name object:(id)object invitationMessage:(XMPPInvitationMessage *)message
{
	[self postNotificationName:name object:object userInfo:[NSDictionary dictionaryWithObject:message forKey:InvitationMessageKey]];
}
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotification Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotification (XMPPInvitationMessage)
- (XMPPInvitationMessage *)invitationMessage
{
	return [[self userInfo] objectForKey:InvitationMessageKey];
}
@end