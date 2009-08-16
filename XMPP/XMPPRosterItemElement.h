//
// jabber:iq:roster <item/> element defined in RFC 3921 B.5.
//

#import "XMPPElement.h"

@class XMPPJID;

typedef enum _XMPPSubscription
{
	XMPPSubscriptionUnknown,
	XMPPSubscriptionNone,
	XMPPSubscriptionTo,
	XMPPSubscriptionFrom,
	XMPPSubscriptionBoth,
	XMPPSubscriptionRemove
} XMPPSubscription;

@interface XMPPRosterItemElement : XMPPElement
@property (nonatomic, readonly, retain)		XMPPJID *jid;
@property (nonatomic, readwrite, copy)		NSSet *groupNames;		// String-values from <group/> entries
@property (nonatomic, readwrite, assign)	BOOL isPendingApproval;	// YES if ask='subscribe'
@property (nonatomic, readwrite, copy)		NSString *nickname;		// nickname
@property (nonatomic, readwrite, assign)	XMPPSubscription subscription;

- (XMPPRosterItemElement *)initWithJID:(XMPPJID *)aJID;

@end
