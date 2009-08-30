//
//  JIMDiscoveryBrowser.h
//  JabberIM
//
//  Created by Roland Moers on 18.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMAccount.h>
#import <JIMChatManager.h>

@interface JIMDiscoveryBrowser : NSWindowController {
	IBOutlet NSOutlineView *discoveryTable;
	
	IBOutlet NSWindow *mucWindow;
	IBOutlet NSTableView *mucTable;
	NSMutableArray *mucChatrooms;
	
	IBOutlet NSWindow *notSupportedWindow;
	
	JIMAccount *account;
}

- (IBAction)cancleSheet:(id)sender;

- (void)openWithAccount:(JIMAccount *)aAccount;

@end
