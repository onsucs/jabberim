//
//  JIMAccount.h
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMChatManager.h>
#import <JIMContactInfoController.h>

extern NSString* const JIMAccountDidFailToConnectNotification;
extern NSString* const JIMAccountDidConnectNotification;

@interface JIMAccount : NSWindowController {
	IBOutlet NSWindow *addContactWindow;
	IBOutlet NSWindow *authorizeContactWindow;
	IBOutlet NSWindow *removeContactWindow;
	
	IBOutlet NSTextField *newContactJIDField;
	IBOutlet NSTextField *newContactNicknameField;
	IBOutlet NSPopUpButton *accountsButton;
	
	IBOutlet NSTextField *contactAskingForAuthorization;
	IBOutlet NSTextField *addContactToRosterWithNickname;
	IBOutlet NSButton *addContactToRoster;
	
	IBOutlet NSTextField *jidToRemove;
	IBOutlet NSTextField *nicknameToRemove;
	IBOutlet NSImageView *contactImageToRemove;
	
	IBOutlet NSTableView *rosterTable;
	IBOutlet NSPopUpButton *statusButton;
	IBOutlet NSSegmentedControl *segmentedToolsButton;
	
	IBOutlet JIMContactInfoController *contactInfoController;
	
	XMPPChatService *xmppService;
	NSMutableArray *buddies;
	NSDictionary *accountDict;
	NSString *error;
	
	id delegate;
}

@property (readonly) XMPPChatService *xmppService;
@property (readonly) NSDictionary *accountDict;
@property (assign) NSString *error;
@property (assign) id delegate;

- (id)initWithAccountDict:(NSDictionary *)newAccountDict;

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
