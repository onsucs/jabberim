//
//  JIMChatViewController.h
//  JabberIM
//
//  Created by Roland Moers on 04.10.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import <JIMChatTextView.h>
#import <JIMSmallCell.h>

@interface JIMChatViewController : NSViewController {
	IBOutlet NSTableView *chatMembersTable;
	
	IBOutlet NSPopUpButton *availableResources;
	
	IBOutlet NSTextField *newMessageField;
	IBOutlet JIMChatTextView *chatTextView;
	
	IBOutlet NSSplitView *chatSplitView;
	IBOutlet NSSplitView *chatTextSplitView;
	
	XMPPChatSession *chatSession;
}

@property (readonly, retain) XMPPChatSession *chatSession;

#pragma mark Init and Dealloc
- (id)initWithChatPartner:(id<XMPPChatPartner>)aPartner message:(XMPPChatMessage *)aMessage;

#pragma mark Buttons
- (IBAction)setResource:(id)sender;
- (IBAction)sendMessage:(id)sender;

@end
