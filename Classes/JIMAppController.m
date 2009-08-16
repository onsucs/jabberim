//
//  JIMAppController.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAppController.h"

@implementation JIMAppController

- (void)awakeFromNib
{
	[accountManager loadAccounts];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSWindow Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)windowWillClose:(NSNotification *)notification
{
	[userDefaultsController save:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSApp Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if(!flag)
		[rosterWindow makeKeyAndOrderFront:nil];
	
	return YES;
}*/

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[userDefaultsController save:self];
	[accountManager saveAccounts];
}

@end
