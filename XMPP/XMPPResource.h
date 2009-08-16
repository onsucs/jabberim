#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "XMPPPresenceStanza.h"
#import "XMPPMessageStanza.h"

@class XMPPJID;
@class XMPPDiscoInfoInfoQuery;

extern NSString* const XMPPResourceDidChangeChatStateNotification;
extern NSString* const XMPPResourceDidBecomeUnavailableNotification;

@interface XMPPResource : NSObject <NSCoding>
{
	@private
	XMPPPresenceStanza *_stanza;	
	NSDate *_lastPresenceUpdate;
	XMPPDiscoInfoInfoQuery *_info;
	XMPPChatState _chatState;
}
@property (nonatomic, readwrite, retain, setter=setJID:) XMPPJID *jid;
@property (nonatomic, readwrite, assign)	XMPPPresenceShow show;
@property (nonatomic, readwrite, copy)		NSString *showString;
@property (nonatomic, readwrite, copy)		NSString *statusString;	// FIXME: Need statusForLangugage:
@property (nonatomic, readwrite, assign)	XMPPPriority priority;
@property (nonatomic, readonly, retain)		NSDate *lastPresenceUpdate;
@property (nonatomic, readwrite, retain)	XMPPDiscoInfoInfoQuery *info;
@property (nonatomic, readonly, assign)		XMPPChatState chatState;
@property (nonatomic, readonly)				NSString *name;

- (id)initWithPresenceStanza:(XMPPPresenceStanza *)presence;		// Should only be called with type=available
- (id)initWithJID:(XMPPJID *)jid;

- (void)updateWithPresenceStanza:(XMPPPresenceStanza *)presence;	// Should only be called with type=available
- (void)updateWithMessageStanza:(XMPPMessageStanza *)message;

- (NSComparisonResult)compare:(XMPPResource *)another;
@end
