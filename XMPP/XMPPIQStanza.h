//
// An <iq/> stanza, as defined in RFC 3921 B.1/B.2
//

#import "XMPPStanza.h"

typedef enum _XMPPIQType
{
	XMPPIQTypeUnknown = 0,
	XMPPIQTypeError,	// <xs:enumeration value='error'/>
	XMPPIQTypeGet,		// <xs:enumeration value='get'/>
	XMPPIQTypeResult,	// <xs:enumeration value='result'/>
	XMPPIQTypeSet		// <xs:enumeration value='set'/>
} XMPPIQType;

@interface XMPPIQStanza : XMPPStanza

- (id)initWithFromJID:(XMPPJID *)from toJID:(XMPPJID *)to type:(XMPPIQType)type;
@property (nonatomic, readwrite, assign)	XMPPIQType type;
@property (nonatomic, readwrite, copy)		NSString *typeString;

@end
