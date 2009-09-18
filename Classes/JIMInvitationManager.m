//
//  JIMInvitationManager.m
//  JabberIM
//
//  Created by Roland Moers on 19.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMInvitationManager.h"

@implementation JIMInvitationManager

- (id)init
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMInvitationManager" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		invitations = [[NSMutableArray alloc] init];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(roomDidInvite:) name:XMPPRoomDidInviteNotification object:nil];
		
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[invitations release];
	
	[super dealloc];
}

#pragma mark Buttons
- (IBAction)accept:(id)sender
{
	XMPPInvitationMessage *invitation = [invitations objectAtIndex:[invitationTable selectedRow]];
	[invitation accept];
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMChatManagerCreateNewChat object:invitation.room];
	[invitations removeObject:invitation];
	[invitationTable reloadData];
	
	if([invitations count] == 0)
		[invitationWindow close];
}

- (IBAction)reject:(id)sender
{
	XMPPInvitationMessage *invitation = [invitations objectAtIndex:[invitationTable selectedRow]];
	[invitation decline];
	[invitations removeObject:invitation];
	[invitationTable reloadData];
	
	if([invitations count] == 0)
		[invitationWindow close];
}

#pragma mark Invitation Table
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [invitations count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{	
	if([[tableColumn identifier] isEqualToString:@"Name"])
		return [[(XMPPInvitationMessage *)[invitations objectAtIndex:rowIndex] inviter] fullString];
	else if([[tableColumn identifier] isEqualToString:@"Room"])
		return [[[(XMPPInvitationMessage *)[invitations objectAtIndex:rowIndex] room] jid] fullString];
	
	return nil;
}

#pragma mark Notifications
- (void)roomDidInvite:(NSNotification *)note
{
	XMPPInvitationMessage *invitation = [note invitationMessage];
	[invitations addObject:invitation];
	
	if(![invitationWindow isVisible])
		[invitationWindow makeKeyAndOrderFront:self];
	
	[invitationTable reloadData];
}

- (void)accountManagerAllAccountsDidDisconnect:(NSNotification *)note
{
	[invitations removeAllObjects];
	[invitationTable reloadData];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	[invitationWindow close];
}

@end
