#import "XMPPChatSession.h"
#import "XMPPChatMessage.h"
#import "XMPPChatManager.h"
#import "XMPPJID.h"
#import "XMPPResource.h"
#import "XMPPChatStateMessage.h"
#import "XMPPRoom.h"
#import "XMPPInvitationMessage.h"
#import "XMPPService.h"
#import "XMPPUser.h"

NSString* const XMPPChatSessionDidSendMessageNotification = @"XMPPChatSessionDidSendMessageNotification";
NSString* const XMPPChatSessionDidReceiveMessageNotification = @"XMPPChatSessionDidReceiveMessageNotification";
NSString* const XMPPChatSessionDidBecomeGroupChatNotification = @"XMPPChatSessionDidBecomeGroupChatNotification";

@interface XMPPChatSession ()
@property (nonatomic, readwrite, retain) id<XMPPChatPartner>chatPartner;
@property (nonatomic, readwrite, retain) XMPPJID *currentJID;
@property (nonatomic, readwrite, assign) XMPPChatState chatState;
@property (nonatomic, readwrite, retain) NSTimer *timer;
@property (nonatomic, readwrite, assign) XMPPChatSessionState chatSessionState;
@property (nonatomic, readwrite, retain) NSMutableSet *pendingInvitees;
@property (nonatomic, readwrite, copy) NSString *pendingInviteReason;
@property (nonatomic, readwrite, retain) NSFileHandle *messageFile;

- (void)resourceDidBecomeUnavailable:(NSNotification *)note;
- (void)timerDidFire:(NSTimer *)timer;
- (void)roomDidEnter:(NSNotification *)note;
- (void)_loadMessages;
- (void)_logMessage:(XMPPMessage *)message;
@end

@implementation XMPPChatSession
@synthesize messages = _messages;
@synthesize chatSessionState = _chatSessionState;
@synthesize chatPartner = _chatPartner;
@synthesize currentJID = _currentJID;
@synthesize chatState = _chatState;
@synthesize timer = _timer;
@synthesize pendingInvitees = _pendingInvitees;
@synthesize pendingInviteReason = _pendingInviteReason;
@synthesize messageFile = _messageFile;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSSet *)chatSessionsForChatPartner:(id<XMPPChatPartner>)aPartner
{
	return [[XMPPChatManager sharedManager] chatSessionsForChatPartner:aPartner];
}

// Private init for XMPPChatManager
- (XMPPChatSession *)initWithChatPartner:(id<XMPPChatPartner>)aChatPartner
{
	self = [super init];
	if (self != nil)
	{
		self.chatPartner = aChatPartner;
		self.chatState = XMPPChatStateActive;
		if ([aChatPartner isKindOfClass:[XMPPRoom class]])	// FIXME: Need an class method for this rather than a class check
		{
			self.chatSessionState = XMPPChatSessionStateGroupChat;
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDidBecomeUnavailable:) name:XMPPResourceDidBecomeUnavailableNotification object:nil];	// FIXME: Is there a way not to observe nil?
	}
	return self;
}

- (id)init
{
	NSAssert(NO, @"Do not alloc XMPPChats. They need to come from the manager.");
	return nil;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[XMPPChatManager sharedManager] removeSession:self];
	[_chatPartner release]; _chatPartner = nil;
	[_timer invalidate]; [_timer release]; _timer = nil;
	[_messages release]; _messages = nil;
	[_currentJID release]; _currentJID = nil;
	[_pendingInvitees release]; _pendingInvitees = nil;
	[_pendingInviteReason release]; _pendingInviteReason = nil;
	[_messageFile release]; _messageFile = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)uniqueIdentifier
{
	return [NSString stringWithFormat:@"<%@ %x>", NSStringFromClass([self class]), self];
}

- (void)setChatState:(XMPPChatState)newState
{
	_chatState = newState;
	NSTimeInterval nextInterval = 0;
	switch (self.chatState)
	{
		case XMPPChatStateUnknown:
		case XMPPChatStateGone:
		{
			nextInterval = 0;
			break;
		}
		case XMPPChatStateActive:
		{
			nextInterval = 120;		// Active -> Inactive 2m
			break;
		}
		case XMPPChatStateComposing:
		{
			nextInterval = 30;		// Composing -> Paused 30s
			break;
		}
		case XMPPChatStateInactive:	// Inactive -> Gone 8m
		{
			nextInterval = 480;
			break;
		}
		case XMPPChatStatePaused:	// Paused -> Inactive 90s
		{
			nextInterval = 90;
			break;
		}
		default:
		{
			NSAssert1(NO, @"Bad chat state: %d", self.chatState);
		}
	}
	
	if (fabs(nextInterval) < FLT_EPSILON)
	{
		self.timer = nil;
	}
	else
	{
		self.timer = [NSTimer scheduledTimerWithTimeInterval:nextInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:NO];
	}
}

- (NSMutableArray *)messages
{
	if (_messages == nil)
	{
		_messages = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return _messages;
}

- (void)setChatPartner:(id<XMPPChatPartner>)aPartner
{
	[aPartner retain];
	[_chatPartner release];
	_chatPartner = aPartner;
	self.currentJID = aPartner.jid;

	// FIXME: Need to more strongly consider the 1:1/group escalation case 
	// and how the logs should work
	[self _loadMessages];
}

- (XMPPService *)service
{
	return self.chatPartner.service;
}

- (NSString *)chatLogDirectory
{
	// ~/Library/Logs/<bundle>/chatlogs
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		return [[[[paths objectAtIndex:0] 
				  stringByAppendingPathComponent:@"Logs"]
				 stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]]
				stringByAppendingPathComponent:@"chatlogs"];
	}
	
	NSAssert(NO, @"Could not find application suport directory.");
	return nil;
}

- (NSString *)sessionName
{
	return [NSString stringWithFormat:@"Chat with %@", [self.chatPartner.jid bareString]];
}

- (void)setIsComposing:(BOOL)flag
{	
	if (flag)
	{
		if (self.chatState != XMPPChatStateComposing)
		{
			self.chatState = XMPPChatStateComposing;
			XMPPChatStateMessage *message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStateComposing service:self.service] autorelease];
			[message send];
		}
	}
	else
	{
		if (self.chatState != XMPPChatStateActive)
		{
			self.chatState = XMPPChatStateActive;
			XMPPChatStateMessage *message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStateActive service:self.service] autorelease];
			[message send];
		}
	}
}

- (BOOL)isGroupChat
{
	return (self.chatSessionState != XMPPChatSessionStateSingleChat);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)enter
{
	self.chatState = XMPPChatStateActive;
	if ([self.chatPartner respondsToSelector:@selector(enter)])
	{
		[(id)self.chatPartner enter];
	}
}

- (void)leave
{
	[self setIsComposing:NO];
	self.timer = nil;	// Don't keep tracking our chatState (this also allows us to -dealloc)
	if ([self.chatPartner respondsToSelector:@selector(leave)])
	{
		[(id)self.chatPartner leave];
	}
}

- (void)sendString:(NSString *)aString
{
	XMPPChatMessage *message = [[[XMPPChatMessage alloc] initWithTo:self.currentJID string:aString service:self.chatPartner.service isGroupChat:self.isGroupChat] autorelease];
	[self sendMessage:message];
}

#if ! TARGET_OS_IPHONE
- (void)sendAttributedString:(NSAttributedString *)anAS
{
	XMPPChatMessage *message = [[[XMPPChatMessage alloc] initWithTo:self.currentJID attributedString:anAS service:self.chatPartner.service isGroupChat:self.isGroupChat] autorelease];
	[self sendMessage:message];
}
#endif

- (void)sendMessage:(XMPPChatMessage *)message
{
	self.chatState = XMPPChatStateActive;
	[message send];
	[self.messages addObject:message];
	[self _logMessage:message];
	[[NSNotificationCenter defaultCenter] postNotificationName:XMPPChatSessionDidSendMessageNotification object:self chatMessage:message];	
}

- (void)receiveMessage:(XMPPChatMessage *)message
{
	if (! self.isGroupChat)
	{
		XMPPJID *jid = [message fromJID];	// If the ChatManager sent it to us, then this is the JID we should respond to.
		self.currentJID = jid;
	}

	if ([message hasBody])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMPPChatSessionDidReceiveMessageNotification object:self chatMessage:message];
		[self.messages addObject:message];
		[self _logMessage:message];
	}
}

- (void)inviteJID:(XMPPJID *)aJID withReason:(NSString *)aReason
{
	switch (self.chatSessionState)
	{
		case XMPPChatSessionStateGroupChat:
		{
			XMPPInvitationMessage *invitation = [[[XMPPInvitationMessage alloc] initWithFromJID:self.service.myJID toJID:aJID groupChatJID:self.currentJID reason:aReason service:self.service] autorelease];
			invitation.hasContinue = YES;
			[invitation send];
			break;
		}
		case XMPPChatSessionStateEscalating:
		{
			XMPPUser *newUser = [XMPPUser userWithJID:aJID service:self.service];
			[self.pendingInvitees addObject:newUser];
			break;
		}
		case XMPPChatSessionStateSingleChat:
		{
			// Escalate this to a group chat
			// First, keep track of who we need to invite later
			XMPPUser *newUser = [XMPPUser userWithJID:aJID service:self.service];
			self.pendingInvitees = [NSMutableSet setWithObjects:newUser, self.chatPartner, nil];
			self.pendingInviteReason = aReason;
			
			// Switch our chat partner to the new room
			NSString *roomName = [NSString stringWithFormat:@"%@-%@-%d", self.service.myJID.user, self.chatPartner.jid.user, (long)[[NSDate date] timeIntervalSinceReferenceDate]];
			NSString *domain = self.service.domain;
			if ( ! [domain hasPrefix:@"conference."] )
			{
				domain = [@"conference." stringByAppendingString:self.service.myJID.domain];	// FIXME: This is a hack. I'm not sure what the rule really is (if any)
			}
			XMPPJID *jid = [XMPPJID jidWithUser:roomName domain:domain resource:nil];	// FIXME: May need to add "conference" if it isn't in there already.
			XMPPRoom *room = [XMPPRoom roomWithJID:jid service:self.service];
			self.chatPartner = room;
			self.chatSessionState = XMPPChatSessionStateEscalating;

			// Create the room
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomDidEnter:) name:XMPPRoomDidEnterNotification object:room];
			[room create];

			// When the room creates, we'll invite folks
			break;
		}
		default:
		{
			NSAssert1(NO, @"Bad chat session state:%d", self.chatSessionState);
		}
	}
}

- (void)escalateToGroupChatInRoom:(XMPPRoom *)room
{
	self.chatPartner = room;
	self.chatSessionState = XMPPChatSessionStateGroupChat;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomDidEnter:) name:XMPPRoomDidEnterNotification object:room];
	[room enter];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Chatstate timer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)timerDidFire:(NSTimer *)timer
{
	XMPPChatStateMessage *message = nil;
	
	switch (self.chatState) {
		case XMPPChatStateUnknown:
		case XMPPChatStateGone:
		{
			break;
		}
		case XMPPChatStateActive:
		{
			self.chatState = XMPPChatStateInactive;		// Active -> Inactive 2m
			message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStateInactive service:self.service] autorelease];
			break;
		}
		case XMPPChatStateComposing:
		{
			self.chatState = XMPPChatStatePaused;		// Composing -> Paused 30s
			message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStatePaused service:self.service] autorelease];
			break;
		}
		case XMPPChatStateInactive:	// Inactive -> Gone 8m
		{
			self.chatState = XMPPChatStateGone;
			message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStateGone service:self.service] autorelease];
			break;
		}
		case XMPPChatStatePaused:	// Paused -> Inactive 90s
		{
			self.chatState = XMPPChatStateInactive;
			message = [[[XMPPChatStateMessage alloc] initWithTo:self.currentJID chatState:XMPPChatStateInactive service:self.service] autorelease];
			break;
		}
		default:
		{
			NSAssert1(NO, @"Bad chatState: %d", self.chatState);
		}
	}
	[message send];	// message may be nil
}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPResource notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resourceDidBecomeUnavailable:(NSNotification *)note
{
	if (! self.isGroupChat)
	{
		// If our partner's resource became unavailble, we should try the bare JID.
		self.currentJID = self.chatPartner.jid;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRoom notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)roomDidEnter:(NSNotification *)note
{
	// We only pay attention to this notification when we're escalating a chat to a groupchat
	XMPPRoom *room = [note object];

	// We only escalate once
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:XMPPRoomDidEnterNotification object:room];
	
	self.chatSessionState = XMPPChatSessionStateGroupChat;

	// Invite our friends
	for (XMPPUser *user in self.pendingInvitees)
	{
		[self inviteJID:user.jid withReason:self.pendingInviteReason];
	}
	
	[nc postNotificationName:XMPPChatSessionDidBecomeGroupChatNotification object:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTimer:(NSTimer *)aTimer
{
	[aTimer retain];
	[_timer invalidate];
	[_timer release];
	_timer = aTimer;
}

- (void)_loadMessages
{
	// FIXME: Consider error legs a bit more; mostly good, but errors aren't reported
	NSString *directory = [self chatLogDirectory];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ( ! [fm fileExistsAtPath:directory] )
	{
		NSError *error;
		if ( ! [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error] )
		{
			NSLog(@"Could not create chatlog directory: %@", error);
			return;
		}
	}
	
	NSString *chatFilePath = [directory stringByAppendingPathComponent:
							  [[self.chatPartner.jid bareString]
							   stringByAppendingPathExtension:@"chatlog"]];
	
	if ( ! [fm fileExistsAtPath:chatFilePath])
	{
		[fm createFileAtPath:chatFilePath contents:nil attributes:nil];
	}
	
	self.messageFile = [NSFileHandle fileHandleForUpdatingAtPath:chatFilePath];
	NSMutableString *messagesXML = [[NSMutableString alloc] initWithData:[self.messageFile readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	[messagesXML insertString:@"<messages>" atIndex:0];
	[messagesXML appendString:@"</messages>"];
	NSXMLDocument *messagesDoc = [[NSXMLDocument alloc] initWithXMLString:messagesXML options:0 error:NULL];
	for (NSXMLElement *element in [[messagesDoc rootElement] elementsForName:@"message"])
	{
		XMPPMessageStanza *stanza = [[XMPPMessageStanza alloc] initWithXMLElement:element];
		XMPPChatMessage *message = [[XMPPChatMessage alloc] initWithMessageStanza:stanza service:self.service];
		[self.messages addObject:message];
		[message release];
		[stanza release];
	}
	[messagesDoc release];
	[messagesXML release];
}

- (void)_logMessage:(XMPPMessage *)message
{
	XMPPMessageStanza *stanza = [[message stanza] copy];
	stanza.delayDate = message.date;
	[self.messageFile writeData:[[stanza XMLStringWithOptions:NSXMLNodeCompactEmptyElement|NSXMLNodePrettyPrint] dataUsingEncoding:NSUTF8StringEncoding]];
	[stanza release];
}
		
@end
