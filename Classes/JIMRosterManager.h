//
//  JIMRosterManager.h
//  JabberIM
//
//  Created by Roland Moers on 16.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMContactInfoController.h>
#import <JIMAccountManager.h>
#import <JIMAccount.h>
#import <JIMChatManager.h>
#import <JIMOutlineCell.h>

@interface JIMRosterManager : NSWindowController {
	IBOutlet NSWindow *addContactWindow;
	IBOutlet NSWindow *removeContactWindow;
	
	IBOutlet NSTextField *newContactJIDField;
	IBOutlet NSTextField *newContactNicknameField;
	IBOutlet NSPopUpButton *accountsButton;
	
	IBOutlet NSTextField *jidToRemove;
	IBOutlet NSTextField *nicknameToRemove;
	IBOutlet NSImageView *contactImageToRemove;
	
	IBOutlet NSOutlineView *rosterTable;
	IBOutlet NSPopUpButton *statusButton;
	IBOutlet NSSegmentedControl *segmentedToolsButton;
	
	IBOutlet JIMContactInfoController *contactInfoController;
	IBOutlet JIMAccountManager *accountManager;
	
	NSMutableArray *buddies;
	NSMutableArray *buddieGroups;
}

- (IBAction)setStatus:(id)sender;
- (IBAction)segmentedToolsButton:(id)sender;
- (IBAction)removeContact:(id)sender;

- (IBAction)showContactInfos:(id)sender;
- (IBAction)startChat:(id)sender;

- (IBAction)okSheet:(id)sender;
- (IBAction)cancleSheet:(id)sender;

- (void)addContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)removeContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)sortBuddies;
- (NSMutableArray *)buddies;

@end
