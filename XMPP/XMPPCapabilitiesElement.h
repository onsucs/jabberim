// <c /> as defined in XEP-0115

#include "XMPPElement.h"
#include "XMPPPresenceStanza.h"

typedef enum _XMPPCapabilitiesHashAlgorithm
{
	XMPPCapabilitiesHashUnknown,
	XMPPCapabilitiesHashSHA1
} XMPPCapabilitiesHashAlgorithm;

@interface XMPPCapabilitiesElement : XMPPElement
// Does not handle Legacy Format ('ext')
@property (nonatomic, readwrite, assign)	XMPPCapabilitiesHashAlgorithm hashAlgorithm;
@property (nonatomic, readwrite, copy)		NSString *node;
@property (nonatomic, readwrite, copy)		NSString *verificationString;
@end

@interface XMPPPresenceStanza (XMPPCapabilties)
@property (nonatomic, readwrite, retain) XMPPCapabilitiesElement *capabilities;
@end