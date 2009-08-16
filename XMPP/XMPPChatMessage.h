//
// A chat message (ingoing or outgoing) defined in RFC3921.2.1 and RFC3921.4
//
#import "XMPPMessage.h"

@interface XMPPChatMessage : XMPPMessage
#if ! TARGET_OS_IPHONE
- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID attributedString:(NSAttributedString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat;
- (id)initWithTo:(XMPPJID *)aToJID attributedString:(NSAttributedString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat;
@property (nonatomic, readonly, copy) NSAttributedString *attributedBody;
#endif

@property (nonatomic, readonly) BOOL isGroupChat;
@property (nonatomic, readonly, copy) NSString *htmlBody;
- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID string:(NSString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat;
- (id)initWithTo:(XMPPJID *)aToJID string:(NSString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat;

- (BOOL)hasBody;
- (NSString *)fromDisplayName;

@end

@interface NSNotificationCenter (XMPPChatMessage)
- (void)postNotificationName:(NSString *)name object:(id)object chatMessage:(XMPPChatMessage *)message;
@end

@interface NSNotification (XMPPChatMessage)
- (XMPPChatMessage *)chatMessage;
@end