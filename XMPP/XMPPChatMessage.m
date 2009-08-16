#import "XMPPChatMessage.h"
#import "XMPPMessageStanza.h"
#import "XMPPService.h"
#import "XMPPJID.h"
#import "XMPPUser.h"

// FIXME: Refactor out the XHTML conversion into reusable code

static NSString* const ChatMessageKey = @"chatMessage";
@interface XMPPChatMessage ()
#if ! TARGET_OS_IPHONE
- (NSXMLElement *)htmlElementForAttributedString:(NSAttributedString *)as;
- (NSString *)styleForAttributes:(NSDictionary *)attributes;
#endif
@end

@implementation XMPPChatMessage

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructors/Destructors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithTo:(XMPPJID *)aToJID string:(NSString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat
{
	return [self initWithFrom:aService.myJID to:aToJID string:aString service:aService isGroupChat:isGroupChat];
}

- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID string:(NSString *)aString service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat
{
	XMPPMessageType type = isGroupChat ? XMPPMessageTypeGroupchat : XMPPMessageTypeChat;
	self = [super initWithFrom:aFromJID to:aToJID type:type service:aService];
	if (self != nil)
	{
		self.stanza.body = aString;
		self.stanza.chatState = XMPPChatStateActive;
	}
	return self;
}

#if ! TARGET_OS_IPHONE
- (id)initWithTo:(XMPPJID *)aToJID attributedString:(NSAttributedString *)as service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat
{
	return [self initWithFrom:aService.myJID to:aToJID attributedString:as service:aService isGroupChat:isGroupChat];
}

- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID attributedString:(NSAttributedString *)as service:(XMPPService *)aService isGroupChat:(BOOL)isGroupChat
{
	self = [self initWithFrom:aFromJID to:aToJID string:[as string] service:aService isGroupChat:isGroupChat];
	if (self != nil)
	{
		[self.stanza addChild:[self htmlElementForAttributedString:as]];
	}
	return self;
}
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isGroupChat
{
	return (self.stanza.type == XMPPMessageTypeGroupchat);
}

- (NSString *)fromDisplayName
{
	if (self.isGroupChat)
	{
		return self.fromJID.resource;
	}
	else
	{
		return [[XMPPUser userWithJID:self.fromJID service:self.service] shortDisplayName];
	}
}

- (NSString *)htmlBody
{
	NSXMLElement *htmlElement = [self.stanza elementForName:@"html" xmlns:@"http://jabber.org/protocol/xhtml-im"];
	if (htmlElement == nil)
	{
		// Some folks (iChat) put it in the wrong namespace
		htmlElement = [self.stanza elementForName:@"html" xmlns:@"http://www.w3.org/1999/xhtml"];
	}
	return [[htmlElement elementForName:@"body" xmlns:@"http://www.w3.org/1999/xhtml"] XMLString];
}

- (BOOL)hasBody
{
	return ([self.body length] > 0);
}

#if ! TARGET_OS_IPHONE
- (NSAttributedString *)attributedBody
{
	NSData *messageData = [[self htmlBody] dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *body = [[[NSAttributedString alloc] initWithHTML:messageData documentAttributes:NULL] autorelease];
	if (body == nil)
	{
		if (self.body != nil)
		{
			body = [[[NSAttributedString alloc] initWithString:self.body] autorelease];
		}
	}
	return body;
}

- (NSXMLElement *)htmlElementForAttributedString:(NSAttributedString *)as
{
	NSXMLElement *bodyElement = [NSXMLElement elementWithName:@"body" xmlns:@"http://www.w3.org/1999/xhtml"];
	NSRange range = {0, NSNotFound};
	for (NSUInteger pos = 0; pos < [as length]; pos = NSMaxRange(range))
	{
		NSDictionary *effectiveAttributes = [as attributesAtIndex:pos effectiveRange:&range];	// FIXME: See if this works well; if not we'll need attributesAtIndex:longestEffectiveRange:inRange:
		NSXMLElement *span = [NSXMLElement elementWithName:@"span" stringValue:[[as string] substringWithRange:range]];
		NSString *style = [self styleForAttributes:effectiveAttributes];
		if ([style length] > 0)
		{
			[span addAttributeWithName:@"style" stringValue:style];
		}
		[bodyElement addChild:span];
	}

	NSXMLElement *htmlElement = [NSXMLElement elementWithName:@"html" xmlns:@"http://jabber.org/protocol/xhtml-im"];
	[htmlElement addChild:bodyElement];
	return htmlElement;
}

- (NSString *)styleForAttributes:(NSDictionary *)attr
{
	// The following attributes are ignored because I don't believe there's a way to express
	// them in XHTML:
	// NSLigatureAttributeName
	// NSBaselineOffsetAttributeName
	// NSKernAttributeName
	// NSStrokeWidthAttributeName
	// NSStrokeColorAttributeName
	// NSUnderlineColorAttributeName
	// NSStrikethroughColorAttributeName
	// NSShadowAttributeName
	// NSExpansionAttributeName
	// NSCursorAttributeName
	// NSToolTipAttributeName
	// NSMarkedClauseSegmentAttributeName
	// NSWritingDirectionAttributeName
		
	NSMutableString *style = [NSMutableString string];
	
	NSFont *font = [attr objectForKey:NSFontAttributeName];
	if (font != nil)
	{
		NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];
		if (traits & NSItalicFontMask)
		{
			[style appendString:@"font-style: italic;"];
		}
		if (traits & NSBoldFontMask)
		{
			[style appendString:@"font-weight: bold;"];
		}
		// Ignoring the following traits:
		//		NSUnboldFontMask = 0x00000004,
		//		NSNonStandardCharacterSetFontMask = 0x00000008,
		//		NSNarrowFontMask = 0x00000010,
		//		NSExpandedFontMask = 0x00000020,
		//		NSCondensedFontMask = 0x00000040,
		//		NSSmallCapsFontMask = 0x00000080,
		//		NSPosterFontMask = 0x00000100,
		//		NSCompressedFontMask = 0x00000200,
		//		NSFixedPitchFontMask = 0x00000400,
		//		NSUnitalicFontMask = 0x01000000
	}
	
	NSParagraphStyle *paragraphStyle = [attr objectForKey:NSParagraphStyleAttributeName];
	if (paragraphStyle != nil)
	{
		// FIXME: Some of these might be useable
		//NSLog(@"paragraphStyle = %@", paragraphStyle);
	}
	
	NSColor *fgColor = [attr objectForKey:NSForegroundColorAttributeName];
	if (fgColor != nil)
	{
		// FIXME: Implement
	}
	
	NSInteger underline = [[attr objectForKey:NSUnderlineStyleAttributeName] integerValue];
	if (underline != 0)
	{
		// FIXME: Implement
	}
	
	BOOL isSuperscript = ([[attr objectForKey:NSSuperscriptAttributeName] integerValue] != 0);
	if (isSuperscript)
	{
		// FIXME: Implement
	}
	
	NSColor *bgColor = [attr objectForKey:NSBackgroundColorAttributeName];
	if (bgColor != nil)
	{
		// FIXME: Implement
	}
	
	NSTextAttachment *textAttachment = [attr objectForKey:NSAttachmentAttributeName];
	if (textAttachment != nil)
	{
		// FIXME: Implement (if possible?)
	}
	
	id link = [attr objectForKey:NSLinkAttributeName];
	if (link != nil)
	{
		// FIXME: Implement
		if ([link isKindOfClass:[NSURL class]])
		{
		}
		else if ([link isKindOfClass:[NSString class]])
		{
		}
		else
		{
		}
	}
	
	NSInteger strikethrough = [[attr objectForKey:NSStrikethroughStyleAttributeName] integerValue];
	if (strikethrough != 0)
	{
		// FIXME: Implement
	}
	
	CGFloat obliqueness = [[attr objectForKey:NSObliquenessAttributeName] floatValue];
	if ( fabs(obliqueness) >= FLT_EPSILON )
	{
		// FIXME: Implement as italic
	}
	return style;
}
#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotificationCenter Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotificationCenter (XMPPChatMessage)
- (void)postNotificationName:(NSString *)name object:(id)object chatMessage:(XMPPChatMessage *)message
{
	[self postNotificationName:name object:object userInfo:[NSDictionary dictionaryWithObject:message forKey:ChatMessageKey]];
 }
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNotification Category
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSNotification (XMPPChatMessage)
- (XMPPChatMessage *)chatMessage
{
	return [[self userInfo] objectForKey:ChatMessageKey];
}
@end