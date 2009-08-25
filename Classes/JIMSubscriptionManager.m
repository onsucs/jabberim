//
//  JIMSubscriptionManager.m
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMSubscriptionManager.h"
#import "XMPP/XMPP.h"

@implementation JIMSubscriptionManager

- (id)init
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMSubscriptionManager" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		requests = [[NSMutableArray alloc] initWithCapacity:1];
		requestsAlsoAdd = [[NSMutableArray alloc] initWithCapacity:1];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(subscriptionRequestDidArrive:) name:XMPPSubscriptionRequestDidArriveNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[requests release];
	[requestsAlsoAdd release];
	
	[super dealloc];
}

#pragma mark IBActions
- (IBAction)approve:(id)sender
{
	XMPPSubscriptionRequest *request = [requests objectAtIndex:[subscriptionTable selectedRow]];
	[request approve];
	
	if([[[subscriptionTable tableColumnWithIdentifier:@"Add"] dataCellForRow:[subscriptionTable selectedRow]] state] == NSOnState)
	{
		XMPPSubscriptionRequest *alsoAddRequest = [[XMPPSubscriptionRequest alloc] initWithToJID:request.fromJID service:request.service];
		[alsoAddRequest send];
		[alsoAddRequest release];
	}
	
	[requests removeObject:request];
	[subscriptionTable reloadData];
	
	if([requests count] == 0)
		[subscriptionWindow close];
}

- (IBAction)reject:(id)sender
{
	XMPPSubscriptionRequest *request = [requests objectAtIndex:[subscriptionTable selectedRow]];
	[request refuse];
	[requests removeObject:request];
	[subscriptionTable reloadData];
	
	if([requests count] == 0)
		[subscriptionWindow close];
}

- (IBAction)setAddRequestingUser:(id)sender
{
	NSLog(@"Setting Add");
	
	if([[[subscriptionTable tableColumnWithIdentifier:@"Add"] dataCellForRow:[subscriptionTable selectedRow]] state] == NSOnState)
		[requestsAlsoAdd replaceObjectAtIndex:[subscriptionTable selectedRow] withObject:[NSNumber numberWithInt:NSOffState]];
	else
		[requestsAlsoAdd replaceObjectAtIndex:[subscriptionTable selectedRow] withObject:[NSNumber numberWithInt:NSOnState]];
	
	[subscriptionTable reloadData];
}

#pragma mark NSTaleView Delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [requests count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{	
	if([[tableColumn identifier] isEqualToString:@"Name"])
		return [[(XMPPSubscriptionRequest *)[requests objectAtIndex:rowIndex] fromJID] fullString];
	else if([[tableColumn identifier] isEqualToString:@"Account"])
		return [[(XMPPSubscriptionRequest *)[requests objectAtIndex:rowIndex] toJID] fullString];
	else if([[tableColumn identifier] isEqualToString:@"Add"])
		return [requestsAlsoAdd objectAtIndex:rowIndex];
	
	return nil;
}

#pragma mark Notifications

- (void)subscriptionRequestDidArrive:(NSNotification *)note
{
	XMPPSubscriptionRequest *request = (XMPPSubscriptionRequest *)[note object];
	[requests addObject:request];
	[requestsAlsoAdd addObject:[NSNumber numberWithInt:NSOnState]];
	
	if(![subscriptionWindow isVisible])
		[subscriptionWindow makeKeyAndOrderFront:self];
	
	[subscriptionTable reloadData];
}

- (void)accountManagerAllAccountsDidDisconnect:(NSNotification *)note
{
	[requests removeAllObjects];
	[subscriptionTable reloadData];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	[subscriptionWindow close];
}

@end
