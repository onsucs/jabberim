//
//  JIMDiscoveryBrowser.m
//  JabberIM
//
//  Created by Roland Moers on 18.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMDiscoveryBrowser.h"

@implementation JIMDiscoveryBrowser

- (id)init
{
	if((self = [super initWithWindowNibName:@"JIMDiscoveryBrowser"]))
	{
		mucChatrooms = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[mucChatrooms release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[discoveryTable setTarget:self];
	[discoveryTable setDoubleAction:@selector(showDetailsForSelectedItem:)];
	
	[mucTable setTarget:self];
	[mucTable setDoubleAction:@selector(openChatForSelectedItem:)];
}

- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:mucWindow];
	[NSApp endSheet:notSupportedWindow];
}

- (void)openWithAccount:(JIMAccount *)aAccount
{
	account = aAccount;
	
	[discoveryTable reloadData];
	
	[self.window makeFirstResponder:discoveryTable];
	[self showWindow:self];
}

- (void)showDetailsForSelectedItem:(id)sender
{
	if([discoveryTable selectedRow] > -1 && [discoveryTable levelForRow:[discoveryTable selectedRow]] > 0)
	{
		XMPPDiscoItemsItemElement *selectedItem = [discoveryTable itemAtRow:[discoveryTable selectedRow]];
		if([account transport:selectedItem hasFeature:@"http://jabber.org/protocol/muc"])
		{
			XMPPDiscoItemsInfoQuery *itemsQuery = [[XMPPDiscoItemsInfoQuery alloc] initWithType:XMPPIQTypeGet to:nil service:account.xmppService];
			[itemsQuery.stanza addAttributeWithName:@"to" stringValue:[[selectedItem jid] domain]];
			[itemsQuery setDelegate:self];
			[itemsQuery send];
		}
		else
		{
			[NSApp beginSheet:notSupportedWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(notSupportedSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
			[NSApp runModalForWindow:notSupportedWindow];
			[notSupportedWindow orderOut:self];
		}
	}
	else
		NSBeep();
}

- (void)openChatForSelectedItem:(id)sender
{
	if([mucTable selectedRow] > -1)
	{
		XMPPRoom *chatroom = [XMPPRoom roomWithJID:[(XMPPDiscoItemsItemElement *)[mucChatrooms objectAtIndex:[mucTable selectedRow]] jid] service:account.xmppService];
		[chatroom enter];
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:chatroom];
	}
	else
		NSBeep();
}

#pragma mark XMPPInfoQuery delegate
- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	if([[note object] isKindOfClass:[XMPPDiscoItemsInfoQuery class]])
	{
		XMPPDiscoItemsInfoQuery *itemsQuery = [note object];
		
		for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
			[mucChatrooms addObject:oneElement];
		
		[mucTable reloadData];
		
		[NSApp beginSheet:mucWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(mucSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
	}
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	//FIXME: Implement
	
	[[note object] release];
}

#pragma mark Account Table Data Source:
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [mucChatrooms count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"Name"])
		return [(XMPPDiscoItemsItemElement *)[[mucChatrooms sortedArrayUsingSelector:@selector(compareByName:)] objectAtIndex:rowIndex] name];
	else if([[tableColumn identifier] isEqualToString:@"JabberID"])
		return [[(XMPPDiscoItemsItemElement *)[[mucChatrooms sortedArrayUsingSelector:@selector(compareByName:)] objectAtIndex:rowIndex] jid] fullString];
	
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

#pragma mark Sheet Delegate Methods:
- (void)mucSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[mucWindow orderOut:self];
	[mucChatrooms removeAllObjects];
}
	
- (void)notSupportedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
}

@end
