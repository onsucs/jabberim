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
	IBOutlet NSTextField *serverField;
	IBOutlet NSOutlineView *discoveryTable;
	
	IBOutlet NSWindow *mucWindow;
	IBOutlet NSTableView *mucTable;
	NSMutableArray *mucChatrooms;
	
	IBOutlet NSWindow *notSupportedWindow;
	
	NSMutableArray *itemsArray;
	XMPPService *service;
}

- (IBAction)cancleSheet:(id)sender;

- (IBAction)setServer:(id)sender;
- (void)openDiscoveryBrowserWithService:(XMPPService *)aService;

@end
