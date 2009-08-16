//
// A series of XMPPChatMessages between us and an abstract entity
//

#import <Foundation/Foundation.h>

extern NSString* const XMPPChatSessionDidSendMessageNotification;
extern NSString* const XMPPChatSessionDidReceiveMessageNotification;	// NOTE: -messages will not include the newest message when this is posted
extern NSString* const XMPPChatSessionDidBecomeGroupChatNotification;

#import "XMPPMessageStanza.h"

@class XMPPService;
@class XMPPChatMessage;
@class XMPPJID;
@class XMPPRoom;

@protocol XMPPChatPartner <NSObject>
@property (nonatomic, readonly, retain) XMPPJID *jid;
@property (nonatomic, readonly, assign) XMPPService *service;
@end

typedef enum _XMPPChatSessionState
{
	XMPPChatSessionStateSingleChat,
	XMPPChatSessionStateEscalating,
	XMPPChatSessionStateGroupChat
} XMPPChatSessionState;

@interface XMPPChatSession : NSObject
{
	@private
	NSMutableArray *_messages;	// Array of XMPPMessage:s
	XMPPChatSessionState _chatSessionState;
	id<XMPPChatPartner> _chatPartner;
	XMPPChatState _chatState;
	XMPPJID *_currentJID;	// JID to send to. May change over time, and may be specific to this session
	NSTimer *_timer;
	NSMutableSet *_pendingInvitees;	// Folks we need to invite once we create a room
	NSString *_pendingInviteReason;
	NSFileHandle *_messageFile;
}

@property (nonatomic, readonly) NSString *uniqueIdentifier;
@property (nonatomic, readonly)	XMPPService *service;
@property (nonatomic, readonly)	NSMutableArray *messages;	// FIXME: Don't expose a mutable
@property (nonatomic, readonly, assign) BOOL isGroupChat;
@property (nonatomic, readonly, copy) NSString *sessionName;
@property (nonatomic, readonly, retain) id<XMPPChatPartner>chatPartner;
@property (nonatomic, readonly, retain) XMPPJID *currentJID;
@property (nonatomic, readonly, assign) XMPPChatState chatState;

+ (NSSet *)chatSessionsForChatPartner:(id<XMPPChatPartner>)aPartner;

- (NSString *)chatLogDirectory;

- (void)sendString:(NSString *)aString;
- (void)sendMessage:(XMPPChatMessage *)message;
- (void)receiveMessage:(XMPPChatMessage *)message;

#if ! TARGET_OS_IPHONE
- (void)sendAttributedString:(NSAttributedString *)anAS;
#endif

// Set to YES every time the user types a key for this chat
// Set to NO if the user clears the chat (or closes the window, etc.)
- (void)setIsComposing:(BOOL)flag;

// FIXME: Rethink enter/leave on the session
- (void)enter;
- (void)leave;

- (void)inviteJID:(XMPPJID *)aJID withReason:(NSString *)aReason;

- (void)escalateToGroupChatInRoom:(XMPPRoom *)room;

@end
