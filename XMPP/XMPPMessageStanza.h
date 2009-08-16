//
// A <message/> stanza, as defined in RFC 3921 B.1/B.2.
//

#import "XMPPStanza.h"

typedef enum _XMPPMessageType
{
	XMPPMessageTypeUnknown = 0,
	XMPPMessageTypeChat,		// <xs:enumeration value='chat'/>
	XMPPMessageTypeError,		// <xs:enumeration value='error'/>
	XMPPMessageTypeGroupchat,	// <xs:enumeration value='groupchat'/>
	XMPPMessageTypeHeadline,	// <xs:enumeration value='headline'/>
	XMPPMessageTypeNormal		// <xs:enumeration value='normal'/>
} XMPPMessageType;

typedef enum _XMPPChatState
{
	XMPPChatStateUnknown = 0,
	XMPPChatStateActive,
	XMPPChatStateComposing,
	XMPPChatStatePaused,
	XMPPChatStateInactive,
	XMPPChatStateGone
} XMPPChatState;

@interface XMPPMessageStanza : XMPPStanza
// FIXME: Need *ForLanguage: for all of these
@property (nonatomic, readwrite, copy)		NSString *subject;	// <xs:element ref='subject'/>
@property (nonatomic, readwrite, copy)		NSString *body;		// <xs:element ref='body'/>
@property (nonatomic, readwrite, copy)		NSString *thread;	// <xs:element ref='thread'/>
@property (nonatomic, readwrite, assign)	XMPPMessageType type;	 // <xs:attribute name='type' use='optional' default='normal'>
@property (nonatomic, readwrite, assign)	XMPPChatState chatState;

- (XMPPMessageStanza *)initWithFromJID:(XMPPJID *)from toJID:(XMPPJID *)to type:(XMPPMessageType)type;

- (NSString *)typeString;

@end
