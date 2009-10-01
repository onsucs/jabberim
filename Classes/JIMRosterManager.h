//
//  JIMRosterManager.h
//  JabberIM
//
//  Created by Roland Moers on 16.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMBuddieInfoController.h>
#import <JIMAccountManager.h>
#import <JIMAccount.h>
#import <JIMChatManager.h>
#import <JIMOutlineCell.h>
#import <JIMGroup.h>

@interface JIMRosterManager : NSWindowController {
	IBOutlet NSWindow *addContactWindow;
	IBOutlet NSWindow *removeContactWindow;
	IBOutlet NSWindow *joinChatroomWindow;
	
	IBOutlet NSTextField *newContactJIDField;
	IBOutlet NSTextField *newContactNicknameField;
	IBOutlet NSPopUpButton *newContactAccountsButton;
	
	IBOutlet NSTextField *jidToRemove;
	IBOutlet NSTextField *nicknameToRemove;
	IBOutlet NSImageView *contactImageToRemove;
	
	IBOutlet NSPopUpButton *chatroomAccountsButton;
	IBOutlet NSTabView *chatroomTabView;
	IBOutlet NSTableView *existingChatroomsTable;
	IBOutlet NSTextField *newChatroomName;
	IBOutlet NSTextField *newChatroomService;
	
	IBOutlet NSOutlineView *rosterTable;
	IBOutlet NSPopUpButton *statusButton;
	IBOutlet NSSegmentedControl *segmentedToolsButton;
	
	IBOutlet JIMAccountManager *accountManager;
	
	NSMutableArray *groups;
}

- (IBAction)chatroomAccountButton:(id)sender;
- (IBAction)setStatus:(id)sender;
- (IBAction)segmentedToolsButton:(id)sender;
- (IBAction)removeContact:(id)sender;
- (IBAction)mainMenuItemPressed:(id)sender;
- (IBAction)showContactInfos:(id)sender;

- (IBAction)startChat:(id)sender;
- (IBAction)joinExistingChatroom:(id)sender;

- (IBAction)okSheet:(id)sender;
- (IBAction)cancleSheet:(id)sender;

- (void)addContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)removeContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)joinChatroomSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
