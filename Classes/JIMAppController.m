//
//  JIMAppController.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAppController.h"

NSSound *newMessageRecievedSound;
NSSound *newMessageSendSound;
NSSound *buddieOnlineSound;
NSSound *buddieOfflineSound;

@implementation JIMAppController

#pragma mark Init and Dealloc
- (void)awakeFromNib
{
	[accountManager loadAccounts];
	
	newMessageRecievedSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Received Message.aiff" byReference:YES];
	newMessageSendSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Received Message.aiff" byReference:YES];
	
	buddieOnlineSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Buddy Logging In.aiff" byReference:YES];
	buddieOfflineSound = [[NSSound alloc] initWithContentsOfFile:@"/Applications/iChat.app/Contents/Resources/Buddy Logging Out.aiff" byReference:YES];
	
	[self setSelectedSettingsView:accountSettingsView];
}

- (void)dealloc
{
	[newMessageRecievedSound release];
	[newMessageSendSound release];
	
	[buddieOnlineSound release];
	[buddieOfflineSound release];
	
	[super dealloc];
}

- (IBAction)switchToAccountSettings:(id)sender
{
	[self setSelectedSettingsView:accountSettingsView];
}

- (IBAction)switchToAdvancedSettings:(id)sender
{
	[self setSelectedSettingsView:advancedSettingsView];
}

- (void)setSelectedSettingsView:(NSView *)newSelectedView
{
	if(!(selectedView == newSelectedView))
	{
		[selectedView removeFromSuperview];
		selectedView = newSelectedView;
		
		NSRect settingsViewFrame = NSMakeRect(selectedView.frame.origin.x,
											  selectedView.frame.origin.y,
											  viewToInsertSettingsView.frame.size.width,
											  viewToInsertSettingsView.frame.size.height);
		
		selectedView.frame = settingsViewFrame;
		[viewToInsertSettingsView addSubview:selectedView];
	}
}

#pragma mark NSWindow Delegate
- (void)windowWillClose:(NSNotification *)notification
{
	[userDefaultsController save:self];
	[accountManager saveAccounts];
}

#pragma mark NSApp Delegate
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if(!flag)
		[rosterManager.window makeKeyAndOrderFront:nil];
	
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[userDefaultsController save:self];
	[accountManager saveAccounts];
}

@end
