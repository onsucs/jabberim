//
//  JIMAppController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMAccountManager.h>
#import <JIMRosterManager.h>

@interface JIMAppController : NSObject {
	IBOutlet NSUserDefaultsController *userDefaultsController;
	IBOutlet JIMAccountManager *accountManager;
	IBOutlet JIMRosterManager *rosterManager;
	
	IBOutlet NSView *viewToInsertSettingsView;
	IBOutlet NSView *accountSettingsView;
	IBOutlet NSView *advancedSettingsView;
	
	NSView *selectedView;
}

- (IBAction)switchToAccountSettings:(id)sender;
- (IBAction)switchToAdvancedSettings:(id)sender;

- (void)setSelectedSettingsView:(NSView *)newSelectedView;

@end
