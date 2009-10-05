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
	IBOutlet NSTextView *buddieInfoTextView;
	
	XMPPUser *xmppUser;
	
	NSMutableDictionary *categoryAttributes;
	NSMutableDictionary *contentAttributes;
}

@property (retain) XMPPUser *xmppUser;

- (void)resetAllFieldsAndResetAvailableResources:(BOOL)resetResources;
- (void)refreshAllFieldsWithResource:(XMPPResource *)resource;

- (IBAction)setGroup:(id)sender;
- (IBAction)setResource:(id)sender;

- (void)addCategoryString:(NSString *)string;
- (void)addContentString:(NSString *)string;
- (void)addCategoryString:(NSString *)categoryStr withContent:(NSString *)contentStr;

@end
