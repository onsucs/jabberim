//
//  JIMChatTextView.m
//  JabberIM
//
//  Created by Roland Moers on 04.10.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatTextView.h"

@interface JIMChatTextView ()
@property (readwrite, retain) XMPPJID *lastMessageFromJID;
@end

@implementation JIMChatTextView

@synthesize lastMessageFromJID;

#pragma mark Init and Dealloc
- (void)awakeFromNib
{
	[self setString:@""];
}

-(void)dealloc
{
	self.lastMessageFromJID = nil;
	
	[super dealloc];
}

#pragma mark Messages
- (void)appendString:(NSString *)string
{
	[self appendString:string alignment:NSCenterTextAlignment];
}

- (void)appendString:(NSString *)string alignment:(NSTextAlignment)alignment;
{
	NSMutableAttributedString *paragraph;
	if(alignment == NSCenterTextAlignment)
	{
		paragraph = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", string]] autorelease];
		[paragraph appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n"] autorelease]];
	}
	else
	{
		paragraph = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", string]] autorelease];
		[paragraph appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	}

	
	NSMutableParagraphStyle *mutableParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mutableParagraphStyle setAlignment:alignment];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
	[attributes setObject:mutableParagraphStyle forKey:NSParagraphStyleAttributeName];
	
	if(alignment == NSCenterTextAlignment)
	{
		[attributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		[attributes setObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
	}
	else
	{
		[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		[attributes setObject:[NSFont boldSystemFontOfSize:13.0] forKey:NSFontAttributeName];
	}
	
	[paragraph addAttributes:attributes range:NSMakeRange(0, [paragraph length])];
	
	[[self textStorage] appendAttributedString:paragraph];
	[self scrollToBottom];
}

- (void)appendMessage:(XMPPChatMessage *)message
{
	if([message.service.myJID isEqual:message.fromJID])
		[self appendMessage:message alignment:NSRightTextAlignment];
	else
		[self appendMessage:message alignment:NSLeftTextAlignment];
}

- (void)appendMessage:(XMPPChatMessage *)message alignment:(NSTextAlignment)alignment
{	
	NSMutableAttributedString *paragraph = [[[message attributedBody] mutableCopy] autorelease];
	[paragraph appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	if(![message.fromJID isEqual:lastMessageFromJID])
		[self appendString:[NSString stringWithFormat:@"%@: ", message.fromJID.bareString] alignment:alignment];
	
	NSMutableParagraphStyle *mutableParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mutableParagraphStyle setAlignment:alignment];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
	[attributes setObject:mutableParagraphStyle forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSFont systemFontOfSize:12.0] forKey:NSFontAttributeName];
	
	[paragraph addAttributes:attributes range:NSMakeRange(0, [paragraph length])];
	
	[[self textStorage] appendAttributedString:paragraph];
	[self scrollToBottom];
	
	self.lastMessageFromJID = message.fromJID;
}

#pragma mark Others
- (void)scrollToBottom
{
	NSScrollView *scrollView = [self enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

@end
