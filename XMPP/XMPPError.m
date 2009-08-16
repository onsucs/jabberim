#import "XMPPError.h"

// Error domains
NSString* const XMPPErrorDomain = @"com.jabber.errorDomain";

// Commonly used userDict keys
NSString* const XMPPErrorKey = @"error";
NSString* const XMPPErrorXMLKey = @"xmlError";

// XEP-0086 Section 3
XMPPErrorCode XMPPErrorStanzaCodeForLegacyCode(unsigned legacyCode)
{
	switch (legacyCode)
	{
		case 302:
		{ 
			return XMPPErrorStanzaRedirect;
		}
		case 400:
		{
			return XMPPErrorStanzaBadRequest;
		}
		case 401:
		{
			return XMPPErrorStanzaNotAuthorized;
		}
		case 402:
		{
			return XMPPErrorStanzaPaymentRequired;
		}
		case 403:
		{
			return XMPPErrorStanzaForbidden;
		}
		case 404:
		{
			return XMPPErrorStanzaItemNotFound;
		}
		case 405:
		{
			return XMPPErrorStanzaNotAllowed;
		}
		case 406:
		{
			return XMPPErrorStanzaNotAcceptable;
		}
		case 407:
		{
			return XMPPErrorStanzaRegistrationRequired;
		}
		case 408:
		{
			return XMPPErrorStanzaRemoteServerTimeout;
		}
		case 409:
		{
			return XMPPErrorStanzaConflict;
		}
		case 500: 
		{
			return XMPPErrorStanzaInternalServerError;
		}
		case 501:
		{
			return XMPPErrorStanzaFeatureNotImplemented;
		}
		case 502:
		case 503:
		{
			return XMPPErrorStanzaServiceUnavailable;
		}
		case 504:
		{
			return XMPPErrorStanzaRemoteServerTimeout;
		}
		case 510:
		{
			return XMPPErrorStanzaServiceUnavailable;
		}
		default:
		{
			return XMPPErrorStanzaUnknown;
		}
	}
}

// XEP-0086 Section 2
unsigned XMPPErrorLegacyCodeForStanzaCode(XMPPErrorCode errorCode)
{
	// Using a switch statement here makes it hard to work with -Wswitch
	if (errorCode <= XMPPErrorStanzaUnknown || errorCode > XMPPErrorStanzaLastErrorCode)
	{
		return 0;
	}
	else if (errorCode == XMPPErrorStanzaBadRequest)
	{
		return 400;
	}
	else if (errorCode == XMPPErrorStanzaConflict)
	{
		return 409;
	}
	else if (errorCode == XMPPErrorStanzaFeatureNotImplemented)
	{
		return 501;
	}
	else if (errorCode == XMPPErrorStanzaForbidden)
	{
		return 403;
	}
	else if (errorCode == XMPPErrorStanzaGone)
	{ 
		return 302;
	}
	else if (errorCode == XMPPErrorStanzaInternalServerError) 
	{
		return 500;
	}
	else if (errorCode == XMPPErrorStanzaItemNotFound)
	{
		return 404;
	}
	else if (errorCode == XMPPErrorStanzaJIDMalformed)
	{
		return 400;
	}
	else if (errorCode == XMPPErrorStanzaNotAcceptable)
	{
		return 406;
	}
	else if (errorCode == XMPPErrorStanzaNotAllowed)
	{
		return 405;
	}
	else if (errorCode == XMPPErrorStanzaNotAuthorized)
	{
		return 401;
	}
	else if (errorCode == XMPPErrorStanzaPaymentRequired)
	{
		return 402;
	}
	else if (errorCode == XMPPErrorStanzaRecipientUnavailble)
	{
		return 404;
	}
	else if (errorCode == XMPPErrorStanzaRedirect)
	{
		return 302;
	}
	else if (errorCode == XMPPErrorStanzaRegistrationRequired)
	{
		return 407;
	}
	else if (errorCode == XMPPErrorStanzaRemoteServerNotFound)
	{
		return 404;
	}
	else if (errorCode == XMPPErrorStanzaRemoteServerTimeout)
	{
		return 504;
	}
	else if (errorCode == XMPPErrorStanzaResourceConstraint)
	{
		return 500;
	}
	else if (errorCode == XMPPErrorStanzaServiceUnavailable)
	{
		return 503;
	}
	else if (errorCode == XMPPErrorStanzaSubscriptionRequired)
	{
		return 407;
	}
	else if (errorCode == XMPPErrorStanzaUndefinedCondition)
	{
		return 500;
	}
	else if (errorCode == XMPPErrorStanzaUnexpectedRequest)
	{
		return 400;
	}
	else
	{
		NSCAssert1(NO, @"Unexpected stanza error code: %d", errorCode);
		return 0;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSError Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSError (XMPPError)
+ (NSError *)errorWithDomain:(NSString *)domain code:(int)code localizedDescription:(NSString *)description
{
	return [NSError errorWithDomain:domain code:code userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)errorWithXMPPXMLElement:(NSXMLElement *)element
{
	// FIXME: Implement to actually read the error...
	return [NSError errorWithDomain:XMPPErrorDomain code:XMPPErrorUnknown userInfo:[NSDictionary dictionaryWithObject:element forKey:XMPPErrorXMLKey]];
}
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotificationCenter Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotificationCenter (XMPPError)
- (void)postNotificationName:(NSString *)name object:(id)object errorDomain:(NSString *)domain errorCode:(NSInteger)code errorDescription:(NSString *)description
{
	NSError *error = [NSError errorWithDomain:domain code:code localizedDescription:description];
	[self postNotificationName:name object:object error:error];
}

- (void)postNotificationName:(NSString *)name object:(id)object error:(NSError *)error
{
	[self postNotificationName:name object:object userInfo:[NSDictionary dictionaryWithObject:error forKey:XMPPErrorKey]];
}
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotification Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotification (XMPPError)
- (NSError *)error
{
	return [[self userInfo] objectForKey:XMPPErrorKey];
}
@end
