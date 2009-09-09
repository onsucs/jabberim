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
	
	IBOutlet NSWindow *tableWindow;
	IBOutlet NSTableView *tableWindowTable;
	NSMutableArray *tableWindowArray;
	
	IBOutlet NSWindow *notSupportedWindow;
	
	JIMAccount *account;
}

#pragma mark Opening
- (void)openWithAccount:(JIMAccount *)aAccount;

#pragma mark Button Methods
- (IBAction)cancleSheet:(id)sender;

@end
