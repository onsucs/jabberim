//
//  JIMSubscriptionManager.h
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JIMSubscriptionManager : NSObject {
	IBOutlet NSWindow *subscriptionWindow;
	IBOutlet NSTableView *subscriptionTable;
	
	NSMutableArray *requests;
	NSMutableArray *requestsAlsoAdd;
}

- (IBAction)approve:(id)sender;
- (IBAction)reject:(id)sender;
- (IBAction)setAddRequestingUser:(id)sender;

@end
