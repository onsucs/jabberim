#import "XMPPChatManager.h"
#import "XMPPUser.h"
#import "XMPPJID.h"
#import "XMPPChatSession.h"
#import "XMPPService.h"
#import "XMPPChatMessage.h"
#import "XMPPInvitationMessage.h"
#import "XMPPRoom.h"

//
// Friend methods
//
@interface XMPPChatSession (XMPPChatManager)
- (XMPPChatSession *)initWithChatPartner:(id<XMPPChatPartner>)aChatPartner;
@end


//
// Private methods
//
@interface XMPPChatManager ()
@property (nonatomic, readonly, retain) NSMutableSet *chats;
- (NSSet *)sessionsForJID:(XMPPJID *)jid;
- (void)addSession:(XMPPChatSession *)aChat;
- (void)serviceDidReceiveMessageStanza:(NSNotification *)note;
@end

//
// Implementation
//
@implementation XMPPChatManager

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (XMPPChatManager *)sharedManager
{
	static XMPPChatManager* sharedManager = nil;
	if (sharedManager == nil)
	{
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (void) dealloc
{
	[_chats release]; _chats = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableSet *)chats
{
	if (_chats == nil)
	{
		// Don't retain values
		CFSetCallBacks callBacks = kCFTypeSetCallBacks;
		callBacks.retain = NULL;
		callBacks.release = NULL;
		_chats = (NSMutableSet *)CFSetCreateMutable(kCFAllocatorDefault, 1, &callBacks);
	}
	return _chats;
}

- (NSSet *)chatSessionsForChatPartner:(id<XMPPChatPartner>)aPartner
{
	NSSet *sessions = [self sessionsForJID:aPartner.jid];
	if ([sessions count] == 0)
	{
		XMPPChatSession *session = [[[XMPPChatSession alloc] initWithChatPartner:aPartner] autorelease];	// Don't call convenience constructor. It calls us
		[self addSession:session];
		sessions = [NSSet setWithObject:session];
	}
	return sessions;
}

- (void)addSession:(XMPPChatSession *)aChat
{
	[self.chats addObject:aChat];
}

- (void)removeSession:(XMPPChatSession *)aChat
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:aChat];
	[self.chats removeObject:aChat];
}

- (NSSet *)sessionsForJID:(XMPPJID *)jid
{
	NSMutableSet *sessions = [NSMutableSet setWithCapacity:1];
	for (XMPPChatSession *session in self.chats)
	{
		if ([session.currentJID isEqual:jid])
		{
			[sessions addObject:session];
		}
	}
	
	if ([sessions count] == 0 && [jid isBareJID])
	{
		for (XMPPChatSession *session in self.chats)
		{
			if ([[session.currentJID bareJID] isEqual:jid])
			{
				[sessions addObject:session];
			}
		}
	}
	return sessions;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPService notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)serviceDidReceiveMessageStanza:(NSNotification *)note
{
	XMPPMessageStanza *messageStanza = (XMPPMessageStanza *)[note stanza];
	XMPPService *service = [note object];
	
	// FIXME: Can chat/groupchat be merged?
	if ([messageStanza type] == XMPPMessageTypeChat)
	{
		// Send incoming chats to the appropriate session (create a new one if needed)
		XMPPUser *user = [XMPPUser userWithJID:[messageStanza fromJID] service:service];
		XMPPChatSession *chat = [[self chatSessionsForChatPartner:user] anyObject];
		XMPPChatMessage *message = [[[XMPPChatMessage alloc] initWithMessageStanza:messageStanza service:service] autorelease];
		[chat receiveMessage:message];
	}
	else if ([messageStanza type] == XMPPMessageTypeGroupchat)
	{
		// Send incoming chats to the appropriate session. We should never get one that we don't know about
		XMPPRoom *room = [XMPPRoom roomWithJID:messageStanza.fromJID service:service];
		XMPPChatSession *chat = [[self chatSessionsForChatPartner:room] anyObject];
		XMPPChatMessage *message = [[[XMPPChatMessage alloc] initWithMessageStanza:messageStanza service:service] autorelease];
		[chat receiveMessage:message];
	}
	else if ([messageStanza type] == XMPPMessageTypeNormal)
	{
		// Group chat invitations
		if ([XMPPInvitationMessage stanzaHasInvitation:messageStanza])
		{
			XMPPInvitationMessage *message = [[[XMPPInvitationMessage alloc] initWithMessageStanza:messageStanza service:service] autorelease];
			XMPPChatSession *existingSession = [[self sessionsForJID:[message.inviter bareJID]] anyObject];	// FIXME: assumes one chat per JID; need to check for threads, or otherwise find "best"
			if (existingSession != nil && [message hasContinue])
			{
				// A <continue> invitation should be automatically accepted if we already have a session with the inviter
				// XEP-0045 7.6
				XMPPRoom *room = [XMPPRoom roomWithJID:message.fromJID service:existingSession.service];
				[existingSession escalateToGroupChatInRoom:room];
			}
			else
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:XMPPRoomDidInviteNotification object:message.room invitationMessage:message];
			}
		}
	}
}

@end
