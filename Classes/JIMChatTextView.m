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
	NSMutableAttributedString *paragraph = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", string]] autorelease];
	[paragraph appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n"] autorelease]];	
	
	NSMutableParagraphStyle *mutableParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mutableParagraphStyle setAlignment:alignment];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
	[attributes setObject:mutableParagraphStyle forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSColor colorWithCalibratedRed:250 green:250 blue:250 alpha:1] forKey:NSBackgroundColorAttributeName]; //FIXME: Not sure why this isn't doing anything
	
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
	[attributes setObject:[NSColor colorWithCalibratedRed:250 green:250 blue:250 alpha:1] forKey:NSBackgroundColorAttributeName]; //FIXME: Not sure why this isn't doing anything
	
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
