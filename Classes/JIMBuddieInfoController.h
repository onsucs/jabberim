//
//  JIMBuddieInfoController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMRosterManager.h>
#import <JIMGroup.h>

extern NSString* const JIMBuddieInfoControllerShowUserNotification;

@class JIMRosterManager;

@interface JIMBuddieInfoController : NSObject {
	IBOutlet JIMRosterManager *rosterManager;
	
	IBOutlet NSPanel *contactInfoPanel;
	IBOutlet NSPopUpButton *availableGroups;
	IBOutlet NSPopUpButton *availableResources;
	IBOutlet NSTextField *timeOfLastActivity;
	IBOutlet NSTextField *status;
	IBOutlet NSTextField *statusRecieved;
	IBOutlet NSTextField *priority;
	IBOutlet NSTextField *clientID;
	IBOutlet NSTextField *clientVersion;
	IBOutlet NSTextField *clientOS;
	
	XMPPUser *xmppUser;
}

@property (retain) XMPPUser *xmppUser;

- (void)resetAllFieldsAndResetAvailableResources:(BOOL)resetResources;
- (void)refreshAllFieldsWithResource:(XMPPResource *)resource;

- (IBAction)setGroup:(id)sender;
- (IBAction)setResource:(id)sender;

@end
