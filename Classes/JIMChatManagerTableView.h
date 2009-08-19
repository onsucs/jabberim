//
//  JIMChatManagerTableView.h
//  JabberIM
//
//  Created by Roland Moers on 19.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JIMChatManagerTableView : NSTableView {
	IBOutlet NSMenu *chatOptionsMenu;
}

- (void)displayChatOptionsMenu:(NSEvent *)event;

@end
