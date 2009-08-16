//
//  XMPPUserManager.h
//  Manages all XMPPUser objects for all XMPPServices.
//  This is an internal object. Higher level objects to talk to XMPPUser.
//  
//  FIXME: We currently retain every user we've ever created.
//         This is because <presence> entries can come in before our roster, so no one
//         would be holding the user in order to save the presence. The fix for this
//         is to start with strong references and switch to weak references after
//         XMPPRosterDidAddUsersNotification comes in for a service.
//

#import "XMPPManager.h"

@class XMPPUser;
@class XMPPJID;
@class XMPPService;

@interface XMPPUserManager : XMPPManager
{
	@private
	NSMutableDictionary *_users;	// Service => { JID(bare) => User }
}

+ (XMPPUserManager *)sharedManager;

- (XMPPUser *)userForJID:(XMPPJID *)aJID service:(XMPPService *)aService;	// Creates a new User if needed
- (void)removeUser:(XMPPUser *)aUser;

@end
