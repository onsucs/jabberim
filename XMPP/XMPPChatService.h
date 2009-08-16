// A connection to a RFC 3921 XMPP IM service

#import <Foundation/Foundation.h>
#import "XMPPService.h"

@class XMPPRoster;
@class XMPPUser;

@interface XMPPChatService : XMPPService
{
	@private
	XMPPRoster *_roster;
	struct
	{
		unsigned int autoRoster:1;
		unsigned int autoPresence:1;
	} _chatServiceFlags;
}
@property (nonatomic, readonly, retain) XMPPRoster *roster;

// Automatically request roster after authenticating? (default:YES)
- (BOOL)autoRoster;
- (void)setAutoRoster:(BOOL)flag;

// Automatically send presence ("go online") after authenticating? (default:YES)
- (BOOL)autoPresence;
- (void)setAutoPresence:(BOOL)flag;

@end
