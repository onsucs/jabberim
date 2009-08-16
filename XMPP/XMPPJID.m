#import "XMPPJID.h"
#import "LibIDN.h"

@implementation XMPPJID
@synthesize user = _user;
@synthesize domain = _domain;
@synthesize resource = _resource;

+ (BOOL)validateUser:(NSString *)user domain:(NSString *)domain resource:(NSString *)resource
{
	// Domain is the only required part of a JID
	if((domain == nil) || ([domain length] == 0)) return NO;
	
	// If there's an @ symbol in the domain it probably means user put @ in their username
	NSRange invalidAtRange = [domain rangeOfString:@"@"];
	if(invalidAtRange.location != NSNotFound) return NO;
	
	// Can't use an empty string resource name
	if((resource != nil) && ([resource length] == 0)) return NO;
	
	return YES;
}

+ (BOOL)parse:(NSString *)jidStr
	  outUser:(NSString **)user
	outDomain:(NSString **)domain
  outResource:(NSString **)resource
{
	*user = nil;
	*domain = nil;
	*resource = nil;
	
	NSString *rawUser = nil;
	NSString *rawDomain = nil;
	NSString *rawResource = nil;
	
	NSRange atRange = [jidStr rangeOfString:@"@"];
	
	if(atRange.location != NSNotFound)
	{
		rawUser = [jidStr substringToIndex:atRange.location];
		
		NSString *minusUser = [jidStr substringFromIndex:atRange.location+1];
		
		NSRange slashRange = [minusUser rangeOfString:@"/"];
		
		if(slashRange.location != NSNotFound)
		{
			rawDomain = [minusUser substringToIndex:slashRange.location];
			rawResource = [minusUser substringFromIndex:slashRange.location+1];
		}
		else
		{
			rawDomain = minusUser;
		}
	}
	else
	{
		NSRange slashRange = [jidStr rangeOfString:@"/"];
				
		if(slashRange.location != NSNotFound)
		{
			rawDomain = [jidStr substringToIndex:slashRange.location];
			rawResource = [jidStr substringFromIndex:slashRange.location+1];
		}
		else
		{
			rawDomain = jidStr;
		}
	}
	
	NSString *prepUser = [LibIDN prepNode:rawUser];
	NSString *prepDomain = [LibIDN prepDomain:rawDomain];
	NSString *prepResource = [LibIDN prepResource:rawResource];
	
	if([XMPPJID validateUser:prepUser domain:prepDomain resource:prepResource])
	{
		*user = prepUser;
		*domain = prepDomain;
		*resource = prepResource;
		
		return YES;
	}
	
	return NO;
}

+ (XMPPJID *)jidWithString:(NSString *)jidStr
{
	if ([jidStr length] == 0)
	{
		return nil;
	}
	
	NSString *user;
	NSString *domain;
	NSString *resource;
	
	if([XMPPJID parse:jidStr outUser:&user outDomain:&domain outResource:&resource])
	{
		XMPPJID *jid = [[XMPPJID alloc] init];
		jid->_user = [user copy];
		jid->_domain = [domain copy];
		jid->_resource = [resource copy];
		
		return [jid autorelease];
	}
	
	return nil;
}

+ (XMPPJID *)jidWithString:(NSString *)jidStr resource:(NSString *)resource
{
	NSString *user;
	NSString *domain;
	NSString *ignore;
	
	if([XMPPJID parse:jidStr outUser:&user outDomain:&domain outResource:&ignore])
	{
		XMPPJID *jid = [[XMPPJID alloc] init];
		jid->_user = [user copy];
		jid->_domain = [domain copy];
		jid->_resource = [resource copy];
		
		return [jid autorelease];
	}
	
	return nil;
}

+ (XMPPJID *)jidWithUser:(NSString *)user domain:(NSString *)domain resource:(NSString *)resource
{
	NSString *prepUser = [LibIDN prepNode:user];
	NSString *prepDomain = [LibIDN prepDomain:domain];
	NSString *prepResource = [LibIDN prepResource:resource];
	
	if([XMPPJID validateUser:prepUser domain:prepDomain resource:prepResource])
	{
		XMPPJID *jid = [[XMPPJID alloc] init];
		jid->_user = [prepUser copy];
		jid->_domain = [prepDomain copy];
		jid->_resource = [prepResource copy];
		
		return [jid autorelease];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Encoding, Decoding:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if ! TARGET_OS_IPHONE
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
	if([encoder isBycopy])
		return self;
	else
		return [NSDistantObject proxyWithLocal:self connection:[encoder connection]];
}
#endif

- (id)initWithCoder:(NSCoder *)coder
{
	if((self = [super init]))
	{
		if([coder allowsKeyedCoding])
		{
			_user     = [[coder decodeObjectForKey:@"user"] copy];
			_domain   = [[coder decodeObjectForKey:@"domain"] copy];
			_resource = [[coder decodeObjectForKey:@"resource"] copy];
		}
		else
		{
			_user     = [[coder decodeObject] copy];
			_domain   = [[coder decodeObject] copy];
			_resource = [[coder decodeObject] copy];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:self.user     forKey:@"user"];
		[coder encodeObject:self.domain   forKey:@"domain"];
		[coder encodeObject:self.resource forKey:@"resource"];
	}
	else
	{
		[coder encodeObject:self.user];
		[coder encodeObject:self.domain];
		[coder encodeObject:self.resource];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Copying:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	// This class is immutable
	return [self retain];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Normal Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPJID *)bareJID
{
	if(self.resource == nil)
	{
		return [[self retain] autorelease];
	}
	else
	{
		return [XMPPJID jidWithUser:self.user domain:self.domain resource:nil];
	}
}

- (NSString *)bareString
{
	if(self.user)
	{
		return [NSString stringWithFormat:@"%@@%@", self.user, self.domain];
	}
	else
	{
		return self.domain;
	}
}

- (NSString *)fullString
{
	if(self.user)
	{
		if(self.resource)
		{
			return [NSString stringWithFormat:@"%@@%@/%@", self.user, self.domain, self.resource];
		}
		else
		{
			return [NSString stringWithFormat:@"%@@%@", self.user, self.domain];
		}
	}
	else
	{
		if(self.resource)
		{
			return [NSString stringWithFormat:@"%@/%@", self.domain, self.resource];
		}
		else
		{
			return self.domain;
		}
	}
}

- (BOOL)isBareJID
{
	return ([self.resource length] == 0);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)hash
{
	return [[self fullString] hash];
}

- (BOOL)isEqual:(id)anObject
{
	if([anObject isMemberOfClass:[self class]])
	{
		XMPPJID *aJID = (XMPPJID *)anObject;
		
		return [[self fullString] isEqualToString:[aJID fullString]];
	}
	return NO;
}

- (NSString *)description
{
	return [self fullString];
}

- (void)dealloc
{
	[_user release]; _user = nil;
	[_domain release]; _domain = nil;
	[_resource release]; _resource = nil;
	[super dealloc];
}

@end
