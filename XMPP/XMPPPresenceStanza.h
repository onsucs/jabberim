//
// A <presence/> stanza, as defined in RFC 3921 B.1/B.2.
//

#import "XMPPStanza.h"

typedef enum _XMPPPresenceType
{
	XMPPPresenceTypeUnknown = 0,
	XMPPPresenceTypeAvailable,		// Absence of a value
	XMPPPresenceTypeError,			// <xs:enumeration value='error'/>
	XMPPPresenceTypeProbe,			// <xs:enumeration value='probe'/>
	XMPPPresenceTypeSubscribe,		// <xs:enumeration value='subscribe'/>
	XMPPPresenceTypeSubscribed,		// <xs:enumeration value='subscribe'/>
	XMPPPresenceTypeUnavailable,	// <xs:enumeration value='unavailable'/>
	XMPPPresenceTypeUnsubscribe,	// <xs:enumeration value='unsubscribe'/>
	XMPPPresenceTypeUnsubscribed	// <xs:enumeration value='unsubscribed'/>	
} XMPPPresenceType;

typedef enum _XMPPPresenceShow
{
	// In order of preference, low to high
	XMPPPresenceShowUnknown = 0,
	XMPPPresenceShowDoNotDisturb,	// <xs:enumeration value='dnd'/>
	XMPPPresenceShowExtendedAway,	// <xs:enumeration value='xa'/>
	XMPPPresenceShowAway,			// <xs:enumeration value='away'/>
	XMPPPresenceShowAvailable,		// Absence of a value RFC 3921 2.2.2.1
	XMPPPresenceShowChat,			// <xs:enumeration value='chat'/>
} XMPPPresenceShow;

typedef SInt8 XMPPPriority;

@interface XMPPPresenceStanza : XMPPStanza

- (XMPPPresenceStanza *)initWithFromJID:(XMPPJID *)from toJID:(XMPPJID *)to type:(XMPPPresenceType)type;

@property (nonatomic, readwrite, assign)	XMPPPresenceType type;
@property (nonatomic, readwrite, copy)		NSString *typeString;
@property (nonatomic, readwrite, assign)	XMPPPresenceShow show;
@property (nonatomic, readwrite, copy)		NSString *showString;
@property (nonatomic, readwrite, copy)		NSString *statusString;	// FIXME: Need statusForLangugage:
@property (nonatomic, readwrite, assign)	XMPPPriority priority;

@end
