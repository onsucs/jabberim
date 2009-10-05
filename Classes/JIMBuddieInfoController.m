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

#pragma mark Init and Dealloc
- (id)init
{
	if((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"JIMBuddieInfoController" owner:self])
			NSLog(@"Error loading Nib for document!");
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBuddieInfo:) name:JIMBuddieInfoControllerShowUserNotification object:nil];
		
		NSMutableParagraphStyle *categoryMutableParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[categoryMutableParagraphStyle setAlignment:NSLeftTextAlignment];
		
		categoryAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
		[categoryAttributes setObject:categoryMutableParagraphStyle forKey:NSParagraphStyleAttributeName];
		[categoryAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		[categoryAttributes setObject:[NSFont systemFontOfSize:13.0] forKey:NSFontAttributeName];
		
		NSMutableParagraphStyle *contentMutableParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[contentMutableParagraphStyle setAlignment:NSRightTextAlignment];
		
		contentAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
		[contentAttributes setObject:contentMutableParagraphStyle forKey:NSParagraphStyleAttributeName];
		[contentAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		[contentAttributes setObject:[NSFont systemFontOfSize:13.0] forKey:NSFontAttributeName];
	}
	return self;
}

- (void)dealloc
{
	[xmppUser release];
	
	[categoryAttributes release];
	[contentAttributes release];
	
	[super dealloc];
}

#pragma mark XMPPUser Setter
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
		
		if([xmppUser.groupNames count] == 0)
			[availableGroups selectItemWithTitle:@"Not grouped"];
		else
			[availableGroups selectItemWithTitle:[xmppUser.groupNames anyObject]];
		
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

#pragma mark Buttons
- (IBAction)setGroup:(id)sender
{
	[xmppUser setGroupNames:[NSSet setWithObject:[sender titleOfSelectedItem]]];
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
	self.xmppUser = [aNotification object];
}

- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
	XMPPIQStanza *iqStanza = [(XMPPInfoQuery *)[note object] stanza];
	
	if([iqStanza elementForName:@"query" xmlns:@"jabber:iq:version"])
	{
		if([[iqStanza elementForName:@"query"] elementForName:@"name"])
		{
			[self addCategoryString:@"Client ID:" withContent:[[[iqStanza elementForName:@"query"] elementForName:@"name"] stringValue]];
		}
		if([[iqStanza elementForName:@"query"] elementForName:@"version"])
			[self addCategoryString:@"Client Version:" withContent:[[[iqStanza elementForName:@"query"] elementForName:@"version"] stringValue]];
		if([[iqStanza elementForName:@"query"] elementForName:@"os"])
			[self addCategoryString:@"Operating System:" withContent:[[[iqStanza elementForName:@"query"] elementForName:@"os"] stringValue]];
	}
	else if([iqStanza elementForName:@"query" xmlns:@"jabber:iq:last"])
		if([[iqStanza elementForName:@"query"] attributeForName:@"seconds"])
			[self addCategoryString:@"Last Activity:" withContent:[[[iqStanza elementForName:@"query"] attributeForName:@"seconds"] stringValue]];
	
	[[note object] release];
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
	// FIXME: Implement
	
	[[note object] release];
}

#pragma mark XMPPRoster Delegate

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

#pragma mark NSWindow Delegate
- (void)windowWillClose:(NSNotification *)notification
{
	self.xmppUser = nil;
}

#pragma mark Others
- (void)resetAllFieldsAndResetAvailableResources:(BOOL)resetResources
{
	if(resetResources)
	{
		[availableResources removeAllItems];
		[availableResources addItemWithTitle:@"Highest Priority"];
		
		for (XMPPResource *oneResource in [xmppUser sortedResources])
			[availableResources addItemWithTitle:[[oneResource jid] fullString]];
		
		[availableGroups removeAllItems];
		
		for(JIMGroup *oneGroup in [rosterManager.groups sortedArrayUsingSelector:@selector(compareByName:)])
			[availableGroups addItemWithTitle:oneGroup.name];
	}
	
	[buddieInfoTextView setString:@""];
}

- (void)refreshAllFieldsWithResource:(XMPPResource *)resource
{
	if([xmppUser isOnline])
	{
		[self addCategoryString:@"Status:"];
		
		if(resource.statusString)
			[self addContentString:resource.statusString];
		else
			[self addContentString:@"Online"];
		
		[self addCategoryString:@"Recieved:" withContent:[resource.lastPresenceUpdate description]];
		[self addCategoryString:@"Priority:" withContent:[NSString stringWithFormat:@"%i", [resource  priority]]];
	}
	else
		[self addCategoryString:@"Status" withContent:@"Offline"];
	
	//if([xmppUser error])
	//[status setStringValue:[xmppUser error]];
}

- (void)addCategoryString:(NSString *)string
{
	NSMutableAttributedString *paragraph = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", string]] autorelease];
	[paragraph addAttributes:categoryAttributes range:NSMakeRange(0, [paragraph length])];
	
	[[buddieInfoTextView textStorage] appendAttributedString:paragraph];
}

- (void)addContentString:(NSString *)string
{
	NSMutableAttributedString *paragraph = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", string]] autorelease];
	[paragraph addAttributes:contentAttributes range:NSMakeRange(0, [paragraph length])];
	
	[[buddieInfoTextView textStorage] appendAttributedString:paragraph];
}

- (void)addCategoryString:(NSString *)categoryStr withContent:(NSString *)contentStr
{
	[self addCategoryString:categoryStr];
	[self addContentString:contentStr];
}

@end
