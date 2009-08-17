//
//  JIMAccountManager.m
//  JabberIM
//
//  Created by Roland Moers on 15.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMAccountManager.h"

NSString* const JIMAccountManagerDidAddNewAccountNotification = @"JIMAccountManagerDidAddNewAccountNotification";
NSString* const JIMAccountManagerDidRemoveAccountNotification = @"JIMAccountManagerDidRemoveAccountNotification";

@implementation JIMAccountManager

@synthesize accounts;

- (id)init
{
	if((self = [super init]))
	{
		accounts = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return self;
}

- (void)awakeFromNib
{
	JIMCell *accountCell = [[[JIMCell alloc] init] autorelease];
	[[accountTable tableColumnWithIdentifier:@"Name"] setDataCell:accountCell];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidFailToConnect:) name:JIMAccountDidFailToConnectNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidConnect:) name:JIMAccountDidConnectNotification object:nil];
}

- (void)dealloc
{
	[accounts release];
	
	[super dealloc];
}

#pragma mark Sheet Actions

- (IBAction)openNewAccountSheet:(id)sender
{
	[self resetNewAccountFields];
	
	[NSApp beginSheet:newAccountSheet modalForWindow:mainSettingsWindow modalDelegate:self didEndSelector:@selector(newAccountSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
	[NSApp runModalForWindow:newAccountSheet];
	[NSApp endSheet:newAccountSheet];
	[newAccountSheet orderOut:self];
}

- (IBAction)openRemoveAccountSheet:(id)sender
{
	if([accountTable selectedRow] != -1)
	{
		[self resetRemoveAccountFields];
		
		if([[(JIMAccount *)[accounts objectAtIndex:[accountTable selectedRow]] xmppService].myJID fullString] && [(JIMAccount *)[accounts objectAtIndex:[accountTable selectedRow]] xmppService].myJID.domain)
		{
			[removeAccountJID setStringValue:[[(JIMAccount *)[accounts objectAtIndex:[accountTable selectedRow]] xmppService].myJID fullString]];
			[removeAccountServer setStringValue:[(JIMAccount *)[accounts objectAtIndex:[accountTable selectedRow]] xmppService].myJID.domain];
			
			[NSApp beginSheet:removeAccountSheet modalForWindow:mainSettingsWindow modalDelegate:self didEndSelector:@selector(removeAccountSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
			[NSApp runModalForWindow:removeAccountSheet];
			[NSApp endSheet:removeAccountSheet];
			[removeAccountSheet orderOut:self];
		}
		else //Invalid account anyway, so just remove it...
		{
			[accounts removeObjectAtIndex:[accountTable selectedRow]];
			[accountTable reloadData];
		}
		
	}
	else
		NSBeep();
}

- (IBAction)okSheet:(id)sender
{
	[NSApp endSheet:newAccountSheet returnCode:NSOKButton];
	[NSApp endSheet:removeAccountSheet returnCode:NSOKButton];
}

- (IBAction)cancleSheet:(id)sender
{
	[NSApp endSheet:newAccountSheet returnCode:NSCancelButton];
	[NSApp endSheet:removeAccountSheet returnCode:NSCancelButton];
}

- (IBAction)editAccount:(id)sender
{
	if([accountTable selectedRow] != -1)
	{
		[self resetNewAccountFields];
		
		NSDictionary *accountDict = [(JIMAccount *)[accounts objectAtIndex:[accountTable selectedRow]] accountDict];
		
		[newAccountJID setStringValue:[accountDict objectForKey:@"JabberID"]];
		[newAccountPassword setStringValue:[accountDict objectForKey:@"Password"]];
		[newAccountResource setStringValue:[accountDict objectForKey:@"Resource"]];
		[newAccountPriority setStringValue:[accountDict objectForKey:@"Priority"]];
		[newAccountServer setStringValue:[accountDict objectForKey:@"Server"]];
		[newAccountPort setStringValue:[accountDict objectForKey:@"Port"]];
		[newAccountAutoLogin setIntValue:[[accountDict objectForKey:@"AutoLogin"] intValue]];
		[newAccountForceOldSSL setIntValue:[[accountDict objectForKey:@"ForceOldSSL"] intValue]];
		[newAccountAllowSelfSignedCerts setIntValue:[[accountDict objectForKey:@"SelfSignedCerts"] intValue]];
		[newAccountAllowHostMismatch setIntValue:[[accountDict objectForKey:@"SSLHostMismatch"] intValue]];
		
		[NSApp beginSheet:newAccountSheet modalForWindow:mainSettingsWindow modalDelegate:self didEndSelector:@selector(editAccountSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
		[NSApp runModalForWindow:newAccountSheet];
		[NSApp endSheet:newAccountSheet];
		[newAccountSheet orderOut:self];
	}
	else
		NSBeep();
}

- (IBAction)jabberIDEntered:(id)sender
{
	if([[sender stringValue] rangeOfString:@"@"].location != NSNotFound)
	{
		XMPPJID *newJID = [XMPPJID jidWithString:[sender stringValue]];
		
		if(newJID)
		{
			[newAccountServer setStringValue:newJID.domain];
			if(newJID.resource)
				[newAccountResource setStringValue:newJID.resource];
		}
	}
}

- (void)resetNewAccountFields
{
	[newAccountJID setStringValue:@""];
	[newAccountPassword setStringValue:@""];
	[newAccountResource setStringValue:@"JabberIM"];
	[newAccountPriority setStringValue:@"1"];
	[newAccountServer setStringValue:@""];
	[newAccountPort setStringValue:@"5222"];
	[newAccountAutoLogin setState:NSOnState];
	[newAccountForceOldSSL setState:NSOffState];
	[newAccountAllowSelfSignedCerts setState:NSOffState];
	[newAccountAllowHostMismatch setState:NSOffState];
	
	[newAccountSheet makeFirstResponder:newAccountJID];
}

- (void)resetRemoveAccountFields
{
	[removeAccountJID setStringValue:@""];
	[removeAccountServer setStringValue:@""];
}

- (void)loadAccounts;
{
	NSArray *accountDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Accounts"];
	
	NSDictionary *oneAccountDict;
	for(oneAccountDict in accountDicts)
	{		
		JIMAccount *newAccount = [[JIMAccount alloc] initWithAccountDict:oneAccountDict];
		[accounts addObject:newAccount];
		[newAccount release];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountManagerDidAddNewAccountNotification object:self];
	[accountTable reloadData];
}

- (void)saveAccounts
{
	NSMutableArray *accountDicts = [[NSMutableArray alloc] initWithCapacity:[accounts count]];
	
	JIMAccount *oneAccount;
	for(oneAccount in accounts)
		[accountDicts addObject:oneAccount.accountDict];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:accountDicts forKey:@"Accounts"];
	[defaults synchronize];
}

#pragma mark Sheet Delegates

- (void)newAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		NSDictionary *accountDict = [NSDictionary dictionaryWithObjectsAndKeys:[newAccountJID stringValue], @"JabberID",
									 [newAccountPassword stringValue], @"Password",
									 [newAccountResource stringValue], @"Resource",
									 [newAccountPriority stringValue], @"Priority",
									 [newAccountServer stringValue], @"Server",
									 [newAccountPort stringValue], @"Port",
									 [NSNumber numberWithInt:[newAccountAutoLogin state]], @"AutoLogin",
									 [NSNumber numberWithInt:[newAccountForceOldSSL state]], @"ForceOldSSL",
									 [NSNumber numberWithInt:[newAccountAllowSelfSignedCerts state]], @"SelfSignedCerts",
									 [NSNumber numberWithInt:[newAccountAllowHostMismatch state]], @"SSLHostMismatch", nil];
		
		JIMAccount *newAccount = [[JIMAccount alloc] initWithAccountDict:accountDict];
		[accounts addObject:newAccount];
		[newAccount release];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountManagerDidAddNewAccountNotification object:self];
		
		[accountTable reloadData];
	}
}

- (void)editAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		[accounts removeObjectAtIndex:[accountTable selectedRow]];
		
		NSDictionary *accountDict = [NSDictionary dictionaryWithObjectsAndKeys:[newAccountJID stringValue], @"JabberID",
									 [newAccountPassword stringValue], @"Password",
									 [newAccountResource stringValue], @"Resource",
									 [newAccountPriority stringValue], @"Priority",
									 [newAccountServer stringValue], @"Server",
									 [newAccountPort stringValue], @"Port",
									 [NSNumber numberWithInt:[newAccountAutoLogin state]], @"AutoLogin",
									 [NSNumber numberWithInt:[newAccountForceOldSSL state]], @"ForceOldSSL",
									 [NSNumber numberWithInt:[newAccountAllowSelfSignedCerts state]], @"SelfSignedCerts",
									 [NSNumber numberWithInt:[newAccountAllowHostMismatch state]], @"SSLHostMismatch", nil];
		
		JIMAccount *newAccount = [[JIMAccount alloc] initWithAccountDict:accountDict];
		[accounts addObject:newAccount];
		[newAccount release];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountManagerDidAddNewAccountNotification object:self];
		
		[accountTable reloadData];
	}
}

- (void)removeAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModal];
	
	if(returnCode == NSOKButton)
	{
		[accounts removeObjectAtIndex:[accountTable selectedRow]];
		[[NSNotificationCenter defaultCenter] postNotificationName:JIMAccountManagerDidRemoveAccountNotification object:self];
		[accountTable reloadData];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Account Table Data Source:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accounts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	JIMAccount *account = [accounts objectAtIndex:rowIndex];
	
	if([[tableColumn identifier] isEqualToString:@"Name"])
	{
		JIMCell *itemCell = [[accountTable tableColumnWithIdentifier:@"Name"] dataCell];
		[itemCell setTitle:[account.xmppService.myJID fullString]];
		
		if(account.error)
			[itemCell setSubtitle:account.error];
		else
			[itemCell setSubtitle:nil];
		
		[itemCell setImage:account.xmppService.serviceIcon];
		
		if([account.xmppService isAuthenticated])
			[itemCell setStatusImage:[NSImage imageNamed:@"available"]];
		else
			[itemCell setStatusImage:[NSImage imageNamed:@"offline"]];
		
		[itemCell setEnabled:YES];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark JIMAccount delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)accountDidConnect:(NSNotification *)note
{
	[accountTable reloadData];
}

- (void)accountDidFailToConnect:(NSNotification *)note
{
	[accountTable reloadData];
}

@end
