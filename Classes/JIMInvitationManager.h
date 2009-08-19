//
//  JIMInvitationManager.h
//  JabberIM
//
//  Created by Roland Moers on 19.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>
#import <JIMChatManager.h>

@interface JIMInvitationManager : NSObject {
	IBOutlet NSWindow *invitationWindow;
	IBOutlet NSTableView *invitationTable;
	
	NSMutableArray *invitations;
}

- (IBAction)accept:(id)sender;
- (IBAction)reject:(id)sender;

@end
