#import "XMPPChatStateMessage.h"
#import "XMPPService.h"

@implementation XMPPChatStateMessage

- (id)initWithTo:(XMPPJID *)aToJID chatState:(XMPPChatState)aChatState service:(XMPPService *)aService
{
	self = [super initWithFrom:aService.myJID to:aToJID type:XMPPMessageTypeChat service:aService];
	if (self != nil)
	{
		self.stanza.chatState = aChatState;
	}
	return self;
}

@end
