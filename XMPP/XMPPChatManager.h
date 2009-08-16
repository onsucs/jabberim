//
// Manages all XMPPChats (regardless of XMPPService).
// Weak refernces to Chats; so if no one else is holding onto it, we forget it.
// This is an internal object. Higher level objects to talk to XMPPChat.
// A key goal of this object is to watch for new incoming chats and create 
// new XMPPChats for them.
//

#import "XMPPManager.h"
#import "XMPPChatSession.h"

@class XMPPUser;
@class XMPPRoom;

@interface XMPPChatManager : XMPPManager
{
	@private
	NSMutableSet *_chats;
}

+ (XMPPChatManager *)sharedManager;

- (NSSet *)chatSessionsForChatPartner:(id<XMPPChatPartner>)aPartner;	// Creates a new Chat if needed

//- (XMPPChatSession *)chatForThread:(NSString *)aThread; // Creates a new Chat if needed

- (void)removeSession:(XMPPChatSession *)aChat;

@end
