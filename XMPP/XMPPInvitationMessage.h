//
// A group chat invitation defined in XEP-0045 7.5
//
#import "XMPPMessage.h"

@class XMPPRoom;
@interface XMPPInvitationMessage : XMPPMessage

+ (BOOL)stanzaHasInvitation:(XMPPMessageStanza *)aStanza;

- (id)initWithFromJID:(XMPPJID *)aFromJID toJID:(XMPPJID *)aToJID groupChatJID:(XMPPJID *)aGroupChat reason:(NSString *)aReason service:(XMPPService *)aService;

@property (nonatomic, readonly) XMPPRoom *room;
@property (nonatomic, readonly) XMPPJID *inviter;
@property (nonatomic, readwrite) BOOL hasContinue;	// FIXME: Also implement -continueThread

- (void)accept;

- (void)decline;
- (void)declineWithReason:(NSString *)aReason;

@end

@interface NSNotificationCenter (XMPPInvitationMessage)
- (void)postNotificationName:(NSString *)name object:(id)object invitationMessage:(XMPPInvitationMessage *)message;
@end

@interface NSNotification (XMPPInvitationMessage)
- (XMPPInvitationMessage *)invitationMessage;
@end