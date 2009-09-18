#import "XMPPUser.h"
#import "XMPPUserManager.h"
#import "XMPPJID.h"
#import "XMPPIQStanza.h"
#import "XMPPResource.h"
#import "XMPPService.h"
#import "XMPPChatMessage.h"
#import "XMPPRosterInfoQuery.h"
#import "XMPPRosterItemElement.h"
#import "XMPPSubscriptionRequest.h"
#import "XMPPUnsubscriptionRequest.h"
#import "SSCrypto.h"
#import "NSDataAdditions.h"

NSString* const XMPPUserDidChangeNameNotification = @"XMPPUserDidChangeNameNotification";
NSString* const XMPPUserDidChangePresenceNotification = @"XMPPUserDidChangePresenceNotification";
NSString* const XMPPUserDidChangeChatStateNotification = @"XMPPUserDidChangeChatStateNotification";

NSString* const XMPPUsersKey = @"users";

@interface XMPPUser ()
@property (nonatomic, readwrite, assign)	XMPPService *service;
@property (nonatomic, readwrite, retain, setter=setJID:) XMPPJID *jid;
@property (nonatomic, readwrite, copy)		NSString *name;
@property (nonatomic, readwrite, assign)	BOOL isPendingApproval;
@property (nonatomic, readwrite, assign)	XMPPSubscription subscription;
@property (nonatomic, readwrite, retain)	NSMutableDictionary *resources;
@property (nonatomic, readwrite, assign)	XMPPChatState chatState;
- (XMPPSubscription)_subscriptionForString:(NSString *)string;
- (void)resourceDidChangeChatState:(NSNotification *)note;
@end

@implementation XMPPUser
@synthesize service = _service;
@synthesize jid = _jid;
@synthesize name = _name;
@synthesize image = _image;
@synthesize isPendingApproval = _isPendingApproval;
@synthesize subscription = _subscription;
@synthesize resources = _resources;
@synthesize groupNames = _groupNames;
@synthesize chatState = _chatState;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)init
{
	NSAssert(NO, @"Do not alloc XMPPUsers. They need to come from the manager.");
	return nil;
}

+ (id)userWithJID:(XMPPJID *)jid service:(XMPPService *)service
{
	return [[XMPPUserManager sharedManager] userForJID:jid service:service];
}

+ (id)userWithRosterItem:(XMPPRosterItemElement *)item service:(XMPPService *)aService
{
	XMPPUser *user = [[XMPPUserManager sharedManager] userForJID:item.jid service:aService];
	[user updateWithRosterItem:item];
	return user;
}

// Private init for XMPPUserManager
- (id)initWithJID:(XMPPJID *)aJid service:(XMPPService *)aService
{
	if((self = [super init]))
	{
		[self setService:aService];
		[self setJID:[aJid bareJID]];
		
		NSImage *newImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:[self pathForSavingImage]]];
		if(newImage)
		{
			self.image = newImage;
			[newImage release];
		}
		else
		{
			XMPPInfoQuery *imageIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:[aJid bareJID] service:aService];
			[imageIQ.stanza addChild:[NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"]];
			[imageIQ setDelegate:self];
			[imageIQ send];
		}
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[XMPPUserManager sharedManager] removeUser:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_jid release]; _jid = nil;
	[_name release]; _name = nil;
	[_groupNames release]; _groupNames = nil;
	_service = nil;
	[_resources release]; _resources = nil;
	[super dealloc];
}

- (NSString *)pathForSavingImage
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	NSString *folder = [NSString stringWithFormat:@"~/Library/Application Support/%@/Images", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
	folder = [folder stringByExpandingTildeInPath];
	
	if(![fileManager fileExistsAtPath:[folder stringByDeletingLastPathComponent]])
		[fileManager createDirectoryAtPath:[folder stringByDeletingLastPathComponent] attributes:nil];
	
	if(![fileManager fileExistsAtPath:folder])
		[fileManager createDirectoryAtPath:folder attributes:nil];
    
	NSString *fileName = [[[self jid] fullString] stringByAppendingString:@".ImageData"];
	return [folder stringByAppendingPathComponent:fileName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSMutableDictionary *)resources
{
	if (_resources == nil)
	{
		_resources = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return _resources;
}

- (void)setService:(XMPPService *)aService
{
	if (_service != aService)
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		if (_service != nil)
		{
			[nc removeObserver:self name:nil object:_service];
		}
		
		[aService retain];
		[_service release];
		_service = aService;
	}
}

- (NSString *)nickname
{
	return [self name];
}

- (void)setNickname:(NSString *)aNickname
{
	[self setName:aNickname];	// Reflect the caller's desire until the change completes. If it fails, we'll set it back.
	
	XMPPRosterInfoQuery *query = [[[XMPPRosterInfoQuery alloc] initWithType:XMPPIQTypeSet service:self.service] autorelease];
	XMPPRosterItemElement *item = [[[XMPPRosterItemElement alloc] initWithJID:self.jid] autorelease];
	item.nickname = aNickname;
	[query addItem:item];
	[query setDelegate:self];
	[query send];
}

- (NSImage *)image
{
	if(_image)
		return _image;
	
	return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Jabber Icon" ofType:@"png"]] autorelease];
}

- (NSString *)shortDisplayName
{
	NSString *nickname = [self nickname];
	return nickname != nil ? nickname : [[self jid] user];
}

- (NSString *)displayName
{
	NSString *nickname = [self nickname];
	return nickname != nil ? nickname : [[self jid] bareString];
}

- (BOOL)isOnline
{
	return ([self primaryResource] != nil);
}

- (XMPPPresenceShow)presenceShow
{
	return self.primaryResource.show;
}

- (NSString *)presenceShowString
{
	return self.primaryResource.showString;
}		

- (NSString *)presenceStatus
{
	return self.primaryResource.statusString;
	
	/*for (XMPPResource *resource in [self sortedResources])
	{
		NSString *status = resource.statusString;
		if ([status length] > 0)
		{
			return status;
		}
	}
	return @"";*/
}	

- (XMPPResource *)primaryResource
{
	XMPPResource *primaryResource = nil;	
	for (XMPPResource *resource in [self unsortedResources])
	{
		if (resource.priority >= 0)	// Never talk to a negative
		{
			if (primaryResource == nil || ([resource compare:primaryResource] == NSOrderedAscending))
			{
				primaryResource = resource;
			}
		}
	}
	return primaryResource;
}

- (XMPPResource *)resourceForJID:(XMPPJID *)aJid
{
	return [[self resources] objectForKey:aJid];
}

- (NSArray *)sortedResources
{
	return [[[self resources] allValues] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)unsortedResources
{
	return [[self resources] allValues];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)subscribe
{
	XMPPSubscriptionRequest *request = [[[XMPPSubscriptionRequest alloc] initWithToJID:self.jid service:self.service] autorelease];
	[request send];
}

- (void)unsubscribe
{
	XMPPSubscriptionRequest *request = [[[XMPPUnsubscriptionRequest alloc] initWithToJID:self.jid service:self.service] autorelease];
	[request send];
}

- (void)deleteFromRoster
{
	NSXMLElement *itemElement = [NSXMLElement elementWithName:@"item"];
	[itemElement addAttributeWithName:@"jid" stringValue:[self.jid bareString]];
	[itemElement addAttributeWithName:@"subscription" stringValue:@"remove"];
	
	NSXMLElement *queryElement = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
	[queryElement addChild:itemElement];
	
	XMPPInfoQuery *removeIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeSet to:nil service:self.service];
	[removeIQ.stanza addChild:queryElement];
	[removeIQ send];
	[removeIQ release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Update Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Roster Item defined in RFC3921.B.5 (jabber:iq:roster). JID is immutable, and so is not set here.
- (void)updateWithRosterItem:(XMPPRosterItemElement *)item
{
	self.isPendingApproval = item.isPendingApproval;
	self.name = item.nickname;
	self.subscription = item.subscription;
	self.groupNames = item.groupNames;
}

// FIXME: When there are multiple resources for a JID, I'm not sure we're always displaying the best one
- (void)updateWithPresenceStanza:(XMPPPresenceStanza *)presence
{
	if([presence elementForName:@"x" xmlns:@"vcard-temp:x:update"]) //Contains vCard update
		if([[presence elementForName:@"x" xmlns:@"vcard-temp:x:update"] elementForName:@"photo"]) //Contains Photo hash, let's see whether we have to reload our beloved photo...
		{
			NSString *serverHashStr = [[[presence elementForName:@"x" xmlns:@"vcard-temp:x:update"] elementForName:@"photo"] stringValue];
			
			NSData * localImageData = [NSData dataWithContentsOfFile:[self pathForSavingImage]];
			NSMutableString *localHashStr = [[[localImageData sha1Digest] description] mutableCopy];
			[localHashStr replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0, [localHashStr length])];
			[localHashStr replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0, [localHashStr length])];
			[localHashStr replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [localHashStr length])];
			
			//Time for logging
			//NSLog(@"User: %@", [[presence fromJID] fullString]);
			//NSLog(@"Server: %@", serverHashStr);
			//NSLog(@"Client: %@", localHashStr);
			
			if(![serverHashStr isEqualToString:localHashStr])
			{
				XMPPInfoQuery *imageIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:[self.jid bareJID] service:self.service];
				[imageIQ.stanza addChild:[NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"]];
				[imageIQ setDelegate:self];
				[imageIQ send];
			}
		}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if([presence type] == XMPPPresenceTypeUnavailable)
	{
		XMPPJID *fromJID = [presence fromJID];
		XMPPResource *resource = [self.resources objectForKey:fromJID];
		[nc removeObserver:self name:nil object:resource];
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPResourceDidBecomeUnavailableNotification object:resource];
		[self.resources removeObjectForKey:fromJID];
	}
	else if ([presence type] == XMPPPresenceTypeAvailable)
	{
		XMPPJID *key = [presence fromJID];
		XMPPResource *resource = [[self resources] objectForKey:key];
		
		if (resource != nil)
		{
			[resource updateWithPresenceStanza:presence];
		}
		else
		{
			XMPPResource *newResource = [[[XMPPResource alloc] initWithPresenceStanza:presence] autorelease];
			[[self resources] setObject:newResource forKey:key];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDidChangeChatState:) name:XMPPResourceDidChangeChatStateNotification object:newResource];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPUserDidChangePresenceNotification object:self stanza:presence];
}

- (void)updateWithMessageStanza:(XMPPMessageStanza *)message
{
	XMPPResource *resource = [self resourceForJID:message.fromJID];
	[resource updateWithMessageStanza:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	XMPPIQStanza *iqStanza = [(XMPPInfoQuery *)[note object] stanza];
	
	if([[iqStanza elementForName:@"vCard"] elementForName:@"PHOTO"]) //Found Image
	{
		NSXMLElement *imageBinVal = [[[iqStanza elementForName:@"vCard"] elementForName:@"PHOTO"] elementForName:@"BINVAL"];
		NSData *base64Data = [[imageBinVal stringValue] dataUsingEncoding:NSASCIIStringEncoding];
		
		NSData *decodedData = nil;
		if([[[[[iqStanza elementForName:@"vCard"] elementForName:@"PHOTO"] elementForName:@"TYPE"] stringValue] isEqualToString:@"image/png"])
			decodedData = [base64Data decodeBase64WithNewLines:NO];
		else if([[[[[iqStanza elementForName:@"vCard"] elementForName:@"PHOTO"] elementForName:@"TYPE"] stringValue] isEqualToString:@"image/jpeg"])
			decodedData = [base64Data decodeBase64WithNewLines:YES];
		else if([[[[[iqStanza elementForName:@"vCard"] elementForName:@"PHOTO"] elementForName:@"TYPE"] stringValue] isEqualToString:@"image/gif"])
			decodedData = [base64Data decodeBase64WithNewLines:NO];
		
		NSImage *newImage = [[NSImage alloc] initWithData:decodedData];
		if(newImage)
		{
			self.image = newImage;
			[decodedData writeToFile:[self pathForSavingImage] atomically:NO];
		}
		[newImage release];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPUserDidChangePresenceNotification object:self stanza:iqStanza];
	}
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	// FIXME: Implement
	
	[[note object] release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Comparison Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the result of invoking compareByName:options: with no options.
**/
- (NSComparisonResult)compareByName:(XMPPUser *)another
{
	return [self compareByName:another options:0];
}

/**
 * This method compares the two users according to their name.
 * If either of the users has no set name (or has an empty string name), the name is considered to be the JID.
 * 
 * Options for the search — you can combine any of the following using a C bitwise OR operator:
 * NSCaseInsensitiveSearch, NSLiteralSearch, NSNumericSearch.
 * See "String Programming Guide for Cocoa" for details on these options.
**/
- (NSComparisonResult)compareByName:(XMPPUser *)another options:(NSStringCompareOptions)mask
{
	NSString *myName = [self displayName];
	NSString *theirName = [another displayName];
	
	return [myName compare:theirName options:mask];
}

/**
 * Returns the result of invoking compareByAvailabilityName:options: with no options.
**/
- (NSComparisonResult)compareByAvailabilityName:(XMPPUser *)another
{
	return [self compareByAvailabilityName:another options:0];
}

/**
 * This method compares the two users according to availability first, and then name.
 * Thus available users come before unavailable users.
 * If both users are available, or both users are not available,
 * this method follows the same functionality as the compareByName:options: as documented above.
**/
- (NSComparisonResult)compareByAvailabilityName:(XMPPUser *)another options:(NSStringCompareOptions)mask
{
	if([self presenceShow] == XMPPPresenceShowAvailable)
	{
		if([another presenceShow] == XMPPPresenceShowAvailable)
		{
			return [self compareByName:another options:mask];
		}
		else
		{
			return NSOrderedAscending;
		}
	}
	else
	{
		if([another presenceShow] == XMPPPresenceShowAvailable)
		{
			return NSOrderedDescending;
		}
		else
		{
			return [self compareByName:another options:mask];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPSubscription)_subscriptionForString:(NSString *)string
{
	if ([string length] == 0)
	{
		return XMPPSubscriptionUnknown;
	}
	else if ([string isEqualToString:@"none"])
	{
		return XMPPSubscriptionNone;
	}
	else if ([string isEqualToString:@"to"])
	{
		return XMPPSubscriptionTo;
	}
	else if ([string isEqualToString:@"from"])
	{
		return XMPPSubscriptionFrom;
	}
	else if ([string isEqualToString:@"both"])
	{
		return XMPPSubscriptionBoth;
	}
	else
	{
		return XMPPSubscriptionUnknown;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)hash
{
	return [[self jid] hash];
}

- (BOOL)isEqual:(id)anObject
{
	if([anObject isMemberOfClass:[self class]])
	{
		XMPPUser *another = (XMPPUser *)anObject;
		
		return [[self jid] isEqual:[another jid]];
	}
	
	return NO;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"XMPPUser: %@", [self jid]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resourceDidChangeChatState:(NSNotification *)note
{
	XMPPResource *resource = [note object];
	XMPPChatState newChatState =[resource chatState];
	if (self.chatState != newChatState)
	{
		self.chatState = newChatState;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPUserDidChangeChatStateNotification object:self];
	}
}		

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Categories
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSNotificationCenter (XMPPUser)
- (void)postNotificationName:(NSString *)name object:(id)object users:(NSSet *)users
{
	[self postNotificationName:name object:object userInfo:[NSDictionary dictionaryWithObject:users forKey:XMPPUsersKey]];
}
@end

@implementation NSNotification (XMPPUser)
- (NSSet *)users
{
	return [[self userInfo] objectForKey:XMPPUsersKey];
}
@end