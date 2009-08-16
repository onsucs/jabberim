//
//  JIMContactInfoController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

@interface JIMContactInfoController : NSObject {
	IBOutlet NSPanel *contactInfoPanel;
	IBOutlet NSPopUpButton *availableResources;
	
	IBOutlet NSTextField *timeOfLastActivity;
	IBOutlet NSTextField *status;
	IBOutlet NSTextField *statusRecieved;
	IBOutlet NSTextField *priority;
	IBOutlet NSTextField *clientID;
	IBOutlet NSTextField *clientVersion;
	IBOutlet NSTextField *clientOS;
	
	BOOL askedForAdditionalInfo;
	XMPPUser *xmppUser;
}

@property (retain) XMPPUser *xmppUser;

- (void)resetAllFieldsAndResetAvailableResources:(BOOL)resetResources;
- (void)refreshAllFieldsWithResource:(XMPPResource *)resource;

- (IBAction)setResource:(id)sender;
@end
