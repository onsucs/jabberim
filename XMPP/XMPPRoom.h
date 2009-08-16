//
// XMPPRoom
// A chat room. XEP-0045


#import <Foundation/Foundation.h>
#import "XMPPChatSession.h"

extern NSString* const XMPPRoomDidInviteNotification;
extern NSString* const XMPPRoomDidAddOccupantNotification;
extern NSString* const XMPPRoomDidRemoveOccupantNotification;
extern NSString* const XMPPRoomDidEnterNotification;
extern NSString* const XMPPRoomDidLeaveNotification;

@class XMPPJID;
@class XMPPService;
@class XMPPUser;
@class XMPPRoomOccupant;
@interface XMPPRoom : NSObject <XMPPChatPartner>
{
	XMPPJID *_myRoomJID;
	NSMutableDictionary *_occupantsForResources; // resource.name => occupant
	BOOL _isJoined;
	XMPPUser *_roomUser;	// The protocol treats rooms as a special kind of user
}
@property (nonatomic, readonly, assign) XMPPService *service;
@property (nonatomic, readonly, retain) XMPPJID *jid;
@property (nonatomic, readonly, copy) NSString *displayName;
@property (nonatomic, readwrite, copy) NSString *nickname;
@property (nonatomic, readonly, assign) BOOL isJoined;
@property (nonatomic, readonly) NSArray *occupants;
@property (nonatomic, readonly, retain) XMPPJID *myRoomJID;
@property (nonatomic, readonly) XMPPRoomOccupant *myRoomOccupant;

+ (id)roomWithJID:(XMPPJID *)jid service:(XMPPService *)service;

- (void)create;
- (void)enter;
- (void)leave;

@end
