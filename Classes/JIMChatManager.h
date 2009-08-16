//
//  JIMChatManager.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>
#import <JIMChatController.h>
#import <JIMCell.h>

extern NSString* const JIMChatManagerCreateNewChat;

@interface JIMChatManager : NSObject {
	IBOutlet NSWindow *chatWindow;
	IBOutlet NSTableView *chatControllerTable;
	IBOutlet NSView *chatControllerView;
	
	NSMutableArray *chatControllerArray;
	NSView *selectedChatView;
}

@property (retain) NSView *selectedChatView;

- (IBAction)stopChat:(id)sender;

@end
