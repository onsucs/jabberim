//  XMPPRoster.h
//  A collection of XMPPUsers from a specific XMPPService. The Roster manages
//  the XMPPUsers, and passes relevant presence and iq stanzas to them.
//  Defined in RFC3921 Section 7.
//  A roster should be requested before initial presence (7.3).
//  Callers should generally request this object using XMPPService -roster.

#import <Foundation/Foundation.h>

extern NSString* const XMPPRosterDidAddUsersNotification;
extern NSString* const XMPPRosterDidRemoveUsersNotification;

@class XMPPService;

@interface XMPPRoster : NSObject
{
	@private
	NSMutableDictionary *_usersForJID;
	XMPPService *_service;	// Does not retain
	NSMutableSet *_requests;
}

+ (XMPPRoster *)rosterWithService:(XMPPService *)service;
- (XMPPRoster *)initWithService:(XMPPService *)service;

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSSet *users;

- (void)requestUpdate;

@end
