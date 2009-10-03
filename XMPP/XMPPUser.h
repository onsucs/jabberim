// XMPPUser.h
// A item of a Roster, as defined in RFC 3921.7.1

#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "XMPPPresenceStanza.h"
#import "XMPPRosterItemElement.h"
#import "XMPPMessageStanza.h"
#import "XMPPChatSession.h"

@class XMPPJID;
@class XMPPIQStanza;
@class XMPPResource;
@class XMPPService;

extern NSString* const XMPPUserDidChangeNameNotification;
extern NSString* const XMPPUserDidChangeGroupsNotification;
extern NSString* const XMPPUserDidChangePresenceNotification;
extern NSString* const XMPPUserDidChangeChatStateNotification;

@interface XMPPUser : NSObject <XMPPChatPartner>
{
	// RFC3921.7.1 fields
	XMPPJID *_jid;
	XMPPSubscription _subscription;
	NSString *_name;
	NSImage *_image;
	NSSet *_groupNames;
	BOOL _isPendingApproval;

	XMPPService *_service;
	
	NSMutableDictionary *_resources;	// Resource for JID
	
	XMPPChatState _chatState;	// Chat state of last resource who talked to us.
}

+ (id)userWithJID:(XMPPJID *)jid service:(XMPPService *)service;
+ (id)userWithRosterItem:(XMPPRosterItemElement *)item service:(XMPPService *)service;

@property (nonatomic, readonly) XMPPService *service;

@property (nonatomic, readonly, retain)	XMPPJID *jid;

@property (nonatomic, readwrite, copy)	NSString *nickname;	// What we call the user. Setting updates the server.
@property (nonatomic, readonly)			NSString *displayName;	// "Best" name for user
@property (nonatomic, readonly)			NSString *shortDisplayName;	// "Best" name for user in a shorter form (without domain for JIDs)
@property (nonatomic, readwrite, retain) NSImage *image;

@property (nonatomic, readwrite, retain) NSSet *groupNames;

@property (nonatomic, readonly)			BOOL isOnline;
@property (nonatomic, readonly)			BOOL isPendingApproval;

@property (nonatomic, readonly)			NSArray *sortedResources;
@property (nonatomic, readonly)			NSArray *unsortedResources;

@property (nonatomic, readonly)			XMPPResource *primaryResource;

@property (nonatomic, readonly)			XMPPPresenceShow presenceShow;
@property (nonatomic, readonly)			NSString *presenceShowString;	// Do not localize; it is the actual text from the XML. It is legal to send a non-standard string, so we need acccess to it.

@property (nonatomic, readonly)			NSString *presenceStatus;

@property (nonatomic, readonly)			XMPPChatState chatState;

- (XMPPResource *)resourceForJID:(XMPPJID *)jid;
- (NSString *)pathForSavingImage;

- (void)subscribe;
- (void)unsubscribe;
- (void)deleteFromRoster;

- (void)updateWithRosterItem:(XMPPRosterItemElement *)item;
- (void)updateWithPresenceStanza:(XMPPPresenceStanza *)presence;
- (void)updateWithMessageStanza:(XMPPMessageStanza *)message;

- (NSComparisonResult)compareByName:(XMPPUser *)another;
- (NSComparisonResult)compareByName:(XMPPUser *)another options:(NSStringCompareOptions)mask;

- (NSComparisonResult)compareByAvailabilityName:(XMPPUser *)another;
- (NSComparisonResult)compareByAvailabilityName:(XMPPUser *)another options:(NSStringCompareOptions)mask;

@end

@interface NSNotificationCenter (XMPPUser)
- (void)postNotificationName:(NSString *)name object:(id)object users:(NSSet *)users;
@end

@interface NSNotification (XMPPUser)
- (NSSet *)users;
@end