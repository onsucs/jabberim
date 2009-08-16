//
//  XMPPChatStateMessage.h
//  Message to update the chatstate
//

#import "XMPPMessage.h"
#import "XMPPMessageStanza.h"

@interface XMPPChatStateMessage : XMPPMessage

- (id)initWithTo:(XMPPJID *)aToJID chatState:(XMPPChatState)aChatState service:(XMPPService *)aService;

@end
