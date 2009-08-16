// XMPPError.h
// Error extensions

#import <Foundation/Foundation.h>
#import "DDXML.h"

// Error domains
extern NSString* const XMPPErrorDomain;

// Commonly used userDict keys
extern NSString* const XMPPErrorKey;
extern NSString* const XMPPErrorXMLKey;

// Error codes
typedef enum _XMPPErrorCode
{
	XMPPErrorUnknown = 0,
	
	// Stream Error codes: RFC3920 4.7.3 "Defined Conditions"
	XMPPErrorStreamUnknown = 100,
	XMPPErrorStreamBadFormat,
	XMPPErrorStreamBadNamespacePrefix,
	XMPPErrorStreamConflict,
	XMPPErrorStreamConnectionTimeout,
	XMPPErrorStreamHostGone,
	XMPPErrorStreamHostUnknown,
	XMPPErrorStreamImproperAddressing,
	XMPPErrorStreamInternalServerError,
	XMPPErrorStreamInvalidFrom,
	XMPPErrorStreamInvalidID,
	XMPPErrorStreamInvalidNamespace,
	XMPPErrorStreamInvalidXML,
	XMPPErrorStreamNotAuthorized,
	XMPPErrorStreamPolicyViolation,
	XMPPErrorStreamRemoteConnectionFailed,
	XMPPErrorStreamResourceConstraint,
	XMPPErrorStreamRestrictedXML,
	XMPPErrorStreamSeeOtherHost,
	XMPPErrorStreamSystemShutdown,
	XMPPErrorStreamUndefinedCondition,
	XMPPErrorStreamUnsupportedEncoding,
	XMPPErrorStreamUnsupportedStanzaType,
	XMPPErrorStreamUnsupportedVersion,
	XMPPErrorStreamXMLNotWellFormed,
	XMPPErrorStreamLastErrorCode = XMPPErrorStreamXMLNotWellFormed,
	
	// SASL Error codes: RFC3920 6.4
	XMPPErrorSASLUnknown = 200,
	XMPPErrorSASLAborted,
	XMPPErrorSASLIncorrectEncoding,
	XMPPErrorSASLInvalidAuthZID,
	XMPPErrorSASLInvalidMechanism,
	XMPPErrorSASLMechanismTooWeak,
	XMPPErrorSASLNotAuthorized,
	XMPPErrorSASLTemporaryAutFailure,
	XMPPErrorSASLLastErrorCode = XMPPErrorSASLTemporaryAutFailure,
	
	// Stanza Error codes: RFC3920 9.3.3
	XMPPErrorStanzaUnknown = 300,
	XMPPErrorStanzaBadRequest,
	XMPPErrorStanzaConflict,
	XMPPErrorStanzaFeatureNotImplemented,
	XMPPErrorStanzaForbidden,
	XMPPErrorStanzaGone,
	XMPPErrorStanzaInternalServerError,
	XMPPErrorStanzaItemNotFound,
	XMPPErrorStanzaJIDMalformed,
	XMPPErrorStanzaNotAcceptable,
	XMPPErrorStanzaNotAllowed,
	XMPPErrorStanzaNotAuthorized,
	XMPPErrorStanzaPaymentRequired,
	XMPPErrorStanzaRecipientUnavailble,
	XMPPErrorStanzaRedirect,
	XMPPErrorStanzaRegistrationRequired,
	XMPPErrorStanzaRemoteServerNotFound,
	XMPPErrorStanzaRemoteServerTimeout,
	XMPPErrorStanzaResourceConstraint,
	XMPPErrorStanzaServiceUnavailable,
	XMPPErrorStanzaSubscriptionRequired,
	XMPPErrorStanzaUndefinedCondition,
	XMPPErrorStanzaUnexpectedRequest,
	XMPPErrorStanzaLastErrorCode = XMPPErrorStanzaUnexpectedRequest,
	
	XMPPErrorLastErrorCode = XMPPErrorStanzaLastErrorCode
} XMPPErrorCode;

// Converting to legacy codes (XEP-0086)
XMPPErrorCode XMPPErrorStanzaCodeForLegacyCode(unsigned legacyCode);
unsigned XMPPErrorLegacyCodeForStanzaCode(XMPPErrorCode errorCode);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSError Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSError (XMPPError)
+ (NSError *)errorWithDomain:(NSString *)domain code:(int)code localizedDescription:(NSString *)description;
+ (NSError *)errorWithXMPPXMLElement:(NSXMLElement *)element;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotificationCenter Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSNotificationCenter (XMPPError)
- (void)postNotificationName:(NSString*)name object:(id)object errorDomain:(NSString*)domain errorCode:(int)code errorDescription:(NSString*)description;
- (void)postNotificationName:(NSString*)name object:(id)object error:(NSError*)error;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotification Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSNotification (XMPPError)
- (NSError*)error;
@end
