//
//  JIMAccountManager.h
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMAccount.h>
#import <JIMCell.h>

extern NSString* const JIMAccountManagerDidAddNewAccountNotification;
extern NSString* const JIMAccountManagerDidRemoveAccountNotification;

@interface JIMAccountManager : NSObject {
	IBOutlet NSWindow *mainSettingsWindow;
	IBOutlet NSWindow *newAccountSheet;
	IBOutlet NSWindow *removeAccountSheet;
	
	IBOutlet NSTextField *newAccountJID;
	IBOutlet NSTextField *newAccountPassword;
	IBOutlet NSTextField *newAccountResource;
	IBOutlet NSTextField *newAccountPriority;
	IBOutlet NSTextField *newAccountServer;
	IBOutlet NSTextField *newAccountPort;
	IBOutlet NSButton *newAccountAutoLogin;
	IBOutlet NSButton *newAccountRegisterUser;
	IBOutlet NSButton *newAccountForceOldSSL;
	IBOutlet NSButton *newAccountAllowSelfSignedCerts;
	IBOutlet NSButton *newAccountAllowHostMismatch;
	
	IBOutlet NSTextField *removeAccountJID;
	IBOutlet NSTextField *removeAccountServer;
	
	IBOutlet NSTableView *accountTable;
	NSMutableArray *accounts;
}

@property (readonly) NSMutableArray *accounts;

- (void)loadAccounts;
- (void)saveAccounts;

- (IBAction)openNewAccountSheet:(id)sender;
- (IBAction)openRemoveAccountSheet:(id)sender;
- (IBAction)setStatus:(id)sender;
- (IBAction)okSheet:(id)sender;
- (IBAction)cancleSheet:(id)sender;
- (IBAction)editAccount:(id)sender;
- (IBAction)jabberIDEntered:(id)sender;

- (void)resetNewAccountFields;
- (void)resetRemoveAccountFields;

@end
