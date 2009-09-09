//
//  JIMDiscoveryBrowser.m
//  JabberIM
//
//  Created by Roland Moers on 18.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMDiscoveryBrowser.h"

@implementation JIMDiscoveryBrowser

#pragma mark Init and Dealloc
- (id)init
{
	if((self = [super initWithWindowNibName:@"JIMDiscoveryBrowser"]))
	{
		tableWindowArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	[tableWindowTable setTarget:self];
	
	[discoveryTable setTarget:self];
	[discoveryTable setDoubleAction:@selector(showDetailsForSelectedItem:)];
}

- (void)dealloc
{
	[tableWindowArray release];
	
	[super dealloc];
}

#pragma mark Opening
- (void)openWithAccount:(JIMAccount *)aAccount
{
	account = aAccount;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidRefreshListOfChatrooms:) name:JIMAccountDidRefreshListOfChatroomsNotification object:account];
	
	[discoveryTable reloadData];
	
	[self.window makeFirstResponder:discoveryTable];
	[self showWindow:self];
}

#pragma mark Button Methods
- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:tableWindow];
	[NSApp endSheet:notSupportedWindow];
}

#pragma mark Table Methods
- (void)showDetailsForSelectedItem:(id)sender
{
	if([discoveryTable selectedRow] > -1 && [discoveryTable levelForRow:[discoveryTable selectedRow]] > 0 && [[discoveryTable itemAtRow:[discoveryTable selectedRow]] isKindOfClass:[XMPPDiscoItemsItemElement class]])
	{
		/*XMPPDiscoItemsItemElement *selectedItem = [discoveryTable itemAtRow:[discoveryTable selectedRow]];
		if([account transport:selectedItem hasFeature:@"http://jabber.org/protocol/muc"])
		{
		}
		else
		{*/
			[NSApp beginSheet:notSupportedWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(notSupportedSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
			[NSApp runModalForWindow:notSupportedWindow];
			[notSupportedWindow orderOut:self];
		//}
	}
	else
		NSBeep();
}

- (void)openChatForSelectedItem:(id)sender
{
	if([tableWindowTable selectedRow] > -1)
	{
		XMPPRoom *chatroom = [XMPPRoom roomWithJID:[(XMPPDiscoItemsItemElement *)[[account chatrooms] objectAtIndex:[tableWindowTable selectedRow]] jid] service:account.xmppService];
		[chatroom enter];
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:chatroom];
	}
	else
		NSBeep();
}

#pragma mark NSTableView Methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[account chatrooms] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"Name"])
		return [(XMPPDiscoItemsItemElement *)[[account chatrooms] objectAtIndex:rowIndex] name];
	else if([[tableColumn identifier] isEqualToString:@"JabberID"])
		return [[(XMPPDiscoItemsItemElement *)[[account chatrooms] objectAtIndex:rowIndex] jid] fullString];
	
	return nil;
}

#pragma mark NSOutlineView delegate
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(item)
	{
		if([item isKindOfClass:[JIMAccount class]])
			return [[item transports] count];
		else
			return 0;
	}
	
	return 1;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if(item)
		return [[account transports] objectAtIndex:index];	
	
	return account;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
{
	if([item isKindOfClass:[JIMAccount class]])
		return YES;
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
{
	if([item isKindOfClass:[XMPPDiscoItemsItemElement class]])
		return [[item jid] fullString];
	else
		return [account.accountDict objectForKey:@"Server"];
	
	return nil;
}

#pragma mark JIMAccount Methods
- (void)accountDidRefreshListOfChatrooms:(NSNotification *)note
{
	[tableWindowTable reloadData];
	[NSApp beginSheet:tableWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(tableWindowSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
}

#pragma mark Sheet Delegate Methods:
- (void)tableWindowSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[tableWindow orderOut:self];
	[tableWindowArray removeAllObjects];
}
	
- (void)notSupportedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
}

#pragma mark NSWindow Delegate Methods:
- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	account = nil;
}

@end
