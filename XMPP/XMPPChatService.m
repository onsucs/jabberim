//  XMPPChatService.m

#import "XMPPChatService.h"
#import "XMPPStream.h"
#import "XMPPRoster.h"
#import "XMPPChatManager.h"
#import "XMPPCapabilityManager.h"
#import "XMPPSubscriptionManager.h"
#import "XMPPUserManager.h"

//
// Private methods
//
@interface XMPPChatService ()
@property (nonatomic, readwrite, retain) XMPPRoster *roster;
@end

//
// Implementation
//
@implementation XMPPChatService
@synthesize roster = _roster;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithDomain:(NSString *)domain port:(UInt16)port jid:(XMPPJID *)jid password:(NSString *)password
{
	if ((self = [super initWithDomain:domain port:port jid:jid password:password]))
	{
		self.autoPresence = YES;
		self.autoRoster = YES;
		self.roster = [XMPPRoster rosterWithService:self];

		// Register managers (some are registered in XMPPService; these are Chat-only)
		[[XMPPUserManager sharedManager] addService:self];
		[[XMPPChatManager sharedManager] addService:self];
		[[XMPPSubscriptionManager sharedManager] addService:self];

		// Register features (chat-only as above)
		XMPPCapabilityManager *cm = [XMPPCapabilityManager sharedManager];
		[cm addFeature:@"http://jabber.org/protocol/muc"];		// XEP-0045 Multi-User Chat
		[cm addFeature:@"http://jabber.org/protocol/xhtml-im"];	// XEP-0071 XHTML-IM
	}
	return self;
}

- (void) dealloc
{
	[[XMPPChatManager sharedManager] removeService:self];
	[_roster release]; _roster = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)autoRoster
{
	return _chatServiceFlags.autoRoster;
}

- (void)setAutoRoster:(BOOL)flag
{
	_chatServiceFlags.autoRoster = flag;
}

- (BOOL)autoPresence
{
	return _chatServiceFlags.autoPresence;
}

- (void)setAutoPresence:(BOOL)flag
{
	_chatServiceFlags.autoPresence = flag;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream callbacks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	[super xmppStreamDidAuthenticate:sender];

	// Note: Order matters in the calls below.
	// We request the roster FIRST, because we need the roster before we can process any presence notifications.
	// We shouldn't receive any presence notification until we've set our presence to available.
	// 
	// We notify the delegate(s) LAST because delegates may be sending their own custom
	// presence packets (and have set autoPresence to NO). The logical place for them to do so is in the
	// onDidAuthenticate method, so we try to request the roster before they start
	// sending any presence packets.
	// 
	// In the event that we do receive any presence elements prior to receiving our roster,
	// we'll be forced to store them in the earlyPresenceElements array, and process them after we finally
	// get our roster list.

	if([self autoRoster])
	{
		[[self roster] requestUpdate];
	}
	if([self autoPresence])
	{
		[self goOnline];
	}
}

@end
