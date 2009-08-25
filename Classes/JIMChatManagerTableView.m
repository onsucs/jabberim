//
//  JIMChatManagerTableView.m
//  JabberIM
//
//  Created by Roland Moers on 19.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMChatManagerTableView.h"

@implementation JIMChatManagerTableView

- (void)mouseDown:(NSEvent *)event
{
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    const NSInteger row = [self rowAtPoint:point];
	
	[super mouseDown:event];
	
	[self setNeedsDisplayInRect:[self rectOfRow:row]];
	[self displayChatOptionsMenu:event];
	[self setNeedsDisplayInRect:[self rectOfRow:row]];
}

- (void)displayChatOptionsMenu:(NSEvent *)event
{
	const NSInteger row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
    if (row < 0)
        return;
	
	if(![[[[self tableColumns] objectAtIndex:[self columnAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]]] identifier] isEqualToString:@"Button"])
		return;
    
    NSEvent *newEvent = [NSEvent mouseEventWithType:[event type] location:[event locationInWindow]
									  modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber]
											context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
    
    [NSMenu popUpContextMenu:chatOptionsMenu withEvent:newEvent forView:self];
}

@end
