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
		itemsArray = [[NSMutableArray alloc] init];
		mucChatrooms = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[mucChatrooms release];
	[itemsArray release];
	
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

- (IBAction)setServer:(id)sender
{
	[itemsArray removeAllObjects];
	
	XMPPDiscoItemsInfoQuery *itemsQuery = [[XMPPDiscoItemsInfoQuery alloc] initWithType:XMPPIQTypeGet to:nil service:service];
	[itemsQuery.stanza addAttributeWithName:@"to" stringValue:[sender stringValue]];
	[itemsQuery setDelegate:self];
	[itemsQuery send];
	
	[discoveryTable reloadData];
}

- (void)openDiscoveryBrowserWithService:(XMPPService *)aService
{
	service = aService;
	
	[self.window makeFirstResponder:discoveryTable];
	
	[serverField setStringValue:[aService.myJID domain]];
	[self setServer:serverField];
	
	[self showWindow:self];
}

- (void)showDetailsForSelectedItem:(id)sender
{
	if([discoveryTable levelForRow:[discoveryTable selectedRow]])
	{
		XMPPDiscoItemsItemElement *selectedItem = [discoveryTable itemAtRow:[discoveryTable selectedRow]];
		
		XMPPDiscoInfoInfoQuery *infoQuery = [[XMPPDiscoInfoInfoQuery alloc] initWithType:XMPPIQTypeGet to:[selectedItem jid] service:service];
		[infoQuery setDelegate:self];
		[infoQuery send];
	}
	else
		NSBeep();
}

- (void)openChatForSelectedItem:(id)sender
{
	if([mucTable selectedRow] > -1)
	{
		XMPPRoom *chatroom = [XMPPRoom roomWithJID:[(XMPPDiscoItemsItemElement *)[mucChatrooms objectAtIndex:[mucTable selectedRow]] jid] service:service];
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
		
		if([[[itemsQuery jid] domain] isEqualToString:[serverField stringValue]])
		{
			for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
				[itemsArray addObject:oneElement];
			
			[discoveryTable reloadData];
		}
		else
		{
			for(XMPPDiscoItemsItemElement *oneElement in [[itemsQuery items] allObjects])
				[mucChatrooms addObject:oneElement];
			
			[mucTable reloadData];
			
			[NSApp beginSheet:mucWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(mucSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
		}
	}
	else if([[note object] isKindOfClass:[XMPPDiscoInfoInfoQuery class]])
	{
		XMPPDiscoInfoInfoQuery *infoQuery = [note object];
		
		if([infoQuery hasFeatureWithName:@"http://jabber.org/protocol/muc"])
		{
			NSLog(@"Loading chatrooms");
			
			XMPPDiscoItemsInfoQuery *itemsQuery = [[XMPPDiscoItemsInfoQuery alloc] initWithType:XMPPIQTypeGet to:nil service:service];
			[itemsQuery.stanza addAttributeWithName:@"to" stringValue:[[infoQuery jid] domain]];
			[itemsQuery setDelegate:self];
			[itemsQuery send];
		}
		else
		{
			NSLog(@"No supported protocol! :(");
			
			[NSApp beginSheet:notSupportedWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
			[NSApp runModalForWindow:notSupportedWindow];
			[notSupportedWindow orderOut:self];
		}
	}
	
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	//FIXME: Implement
	
	[[note object] release];
}

#pragma mark Account Table Data Source:
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [mucChatrooms count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"Name"])
		return [(XMPPDiscoItemsItemElement *)[mucChatrooms objectAtIndex:rowIndex] name];
	else if([[tableColumn identifier] isEqualToString:@"JabberID"])
		return [[(XMPPDiscoItemsItemElement *)[mucChatrooms objectAtIndex:rowIndex] jid] fullString];
	
	return nil;
}

#pragma mark NSOutlineView delegate
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(item)
	{
		if([item isKindOfClass:[XMPPService class]])
			return [itemsArray count];
		else if([item isKindOfClass:[NSDictionary class]])
			return 0;
	}
	
	return 1;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if(item)
		return [itemsArray objectAtIndex:index];	
	
	return service;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
{
	if([item isKindOfClass:[XMPPService class]])
		return YES;
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
{
	if([item isKindOfClass:[XMPPDiscoItemsItemElement class]])
		return [[item jid] fullString];
	else
		return [serverField stringValue];
	
	return nil;
}

#pragma mark Sheet Delegate Methods:
- (void)mucSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[mucWindow orderOut:self];
	[mucChatrooms removeAllObjects];
}
	
	

@end
