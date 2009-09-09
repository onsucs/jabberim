//
//  JIMBuddieInfoController.m
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMBuddieInfoController.h"

NSString* const JIMBuddieInfoControllerShowUserNotification = @"JIMBuddieInfoControllerShowUserNotification";

@implementation JIMBuddieInfoController

@synthesize xmppUser;

- (id)init
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMBuddieInfoController" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(showBuddieInfo:) name:JIMBuddieInfoControllerShowUserNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[xmppUser release];
	
	[super dealloc];
}

- (void)resetAllFieldsAndResetAvailableResources:(BOOL)resetResources
{
	if(resetResources)
	{
		[availableResources removeAllItems];
		[availableResources addItemWithTitle:@"Highest Priority"];
		
		XMPPResource *oneResource;
		for (oneResource in [xmppUser sortedResources])
			[availableResources addItemWithTitle:[[oneResource jid] fullString]];
	}
	
	[timeOfLastActivity setStringValue:@"Not available"];
	[status setStringValue:@"Not available"];
	[statusRecieved setStringValue:@"Not available"];
	[priority setStringValue:@"Not available"];
	[clientID setStringValue:@"Not available"];
	[clientVersion setStringValue:@"Not available"];
	[clientOS setStringValue:@"Not available"];
}

- (void)refreshAllFieldsWithResource:(XMPPResource *)resource
{
	if([xmppUser isOnline])
	{
		[priority setStringValue:[NSString stringWithFormat:@"%i", [resource  priority]]];
		
		if(resource.statusString)
			[status setStringValue:resource.statusString];
		else
			[status setStringValue:@"Online"];
		
		[statusRecieved setObjectValue:resource.lastPresenceUpdate];
	}
	else
		[status setStringValue:@"Offline"];
	
	//if([xmppUser error])
		//[status setStringValue:[xmppUser error]];
}

- (void)setXmppUser:(XMPPUser *)newXmppUser;
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:XMPPUserDidChangePresenceNotification object:xmppUser];
	[nc removeObserver:self name:XMPPUserDidChangeNameNotification object:xmppUser];
	
	[xmppUser release];
	xmppUser = newXmppUser;;
	
	if(xmppUser)
	{
		[xmppUser retain];
		
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangePresenceNotification object:xmppUser];
		[nc addObserver:self selector:@selector(userDidChange:) name:XMPPUserDidChangeNameNotification object:xmppUser];
		
		[self resetAllFieldsAndResetAvailableResources:YES];
		[self refreshAllFieldsWithResource:[xmppUser primaryResource]];
		
		XMPPJID *toJID;
		if([[availableResources titleOfSelectedItem] isEqualToString:@"Highest Priority"])
			toJID = xmppUser.primaryResource.jid;
		else
			toJID = [XMPPJID jidWithString:[availableResources titleOfSelectedItem]];
		
		XMPPInfoQuery *versionIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:toJID service:xmppUser.service];
		[versionIQ.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:version"]];
		[versionIQ setDelegate:self];
		[versionIQ send];
		
		XMPPInfoQuery *lastIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:toJID service:xmppUser.service];
		[lastIQ.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:last"]];
		[lastIQ setDelegate:self];
		[lastIQ send];
		
		[contactInfoPanel makeKeyAndOrderFront:self];
	}
}

- (IBAction)setResource:(id)sender
{
	[self resetAllFieldsAndResetAvailableResources:NO];
	
	XMPPJID *toJID = nil;
	
	if([[sender titleOfSelectedItem] isEqualToString:@"Highest Priority"])
	{
		[self refreshAllFieldsWithResource:[xmppUser primaryResource]];
		toJID = xmppUser.primaryResource.jid;
	}
	else
	{
		XMPPResource *oneResource;
		for (oneResource in [xmppUser sortedResources])
		{
			if([[[oneResource jid] fullString] isEqualToString:[sender titleOfSelectedItem]])
			{
				[self refreshAllFieldsWithResource:oneResource];
				toJID = oneResource.jid;
			}
		}
	}
	
	XMPPInfoQuery *versionIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:toJID service:xmppUser.service];
	[versionIQ.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:version"]];
	[versionIQ setDelegate:self];
	[versionIQ send];
	
	XMPPInfoQuery *lastIQ = [[XMPPInfoQuery alloc] initWithType:XMPPIQTypeGet to:toJID service:xmppUser.service];
	[lastIQ.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:last"]];
	[lastIQ setDelegate:self];
	[lastIQ send];
}

#pragma mark Notifications

- (void)showBuddieInfo:(NSNotification *)aNotification
{
	[self setXmppUser:[aNotification object]];
}

- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	XMPPIQStanza *iqStanza = [(XMPPInfoQuery *)[note object] stanza];
	
	if([iqStanza elementForName:@"query" xmlns:@"jabber:iq:version"])
	{
		if([[iqStanza elementForName:@"query"] elementForName:@"name"])
			[clientID setStringValue:[[[iqStanza elementForName:@"query"] elementForName:@"name"] stringValue]];
		if([[iqStanza elementForName:@"query"] elementForName:@"version"])
			[clientVersion setStringValue:[[[iqStanza elementForName:@"query"] elementForName:@"version"] stringValue]];
		if([[iqStanza elementForName:@"query"] elementForName:@"os"])
			[clientOS setStringValue:[[[iqStanza elementForName:@"query"] elementForName:@"os"] stringValue]];
	}
	else if([iqStanza elementForName:@"query" xmlns:@"jabber:iq:last"])
		if([[iqStanza elementForName:@"query"] attributeForName:@"seconds"])
			[timeOfLastActivity setStringValue:[[[iqStanza elementForName:@"query"] attributeForName:@"seconds"] stringValue]];
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	// FIXME: Implement
	
	[[note object] release];
}

#pragma mark XMPPRoster delegate

- (void)userDidChange:(NSNotification *)note
{
	if(self.xmppUser)
	{
		NSString *selectedItem = [availableResources titleOfSelectedItem];
		[self resetAllFieldsAndResetAvailableResources:YES];
		if([availableResources itemWithTitle:selectedItem])
			[availableResources selectItemWithTitle:selectedItem];
		else
			[availableResources selectItemWithTitle:@"Highest Priority"];
		
		if([[availableResources titleOfSelectedItem] isEqualToString:@"Highest Priority"])
			[self refreshAllFieldsWithResource:[xmppUser primaryResource]];
		else
		{
			XMPPResource *oneResource;
			for (oneResource in [xmppUser sortedResources])
			{
				if([[[oneResource jid] fullString] isEqualToString:[availableResources titleOfSelectedItem]])
					[self refreshAllFieldsWithResource:oneResource];
			}
		}
	}
}

#pragma mark NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification
{
	self.xmppUser = nil;
}

@end
