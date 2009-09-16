//
//  JIMService.m
//  JabberIM
//
//  Created by Roland Moers on 10.09.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMService.h"

@implementation JIMService

#pragma mark Init and Dealloc
- (id)initWithDiscoItemsItem:(XMPPDiscoItemsItemElement *)discoItemsItem service:(XMPPService *)xmppService
{
	if((self = [super init]))
	{
		service = xmppService;
		[service retain];
		
		itemElement = discoItemsItem;
		[itemElement retain];
		
		featureQuery = [[XMPPDiscoInfoInfoQuery alloc] initWithType:XMPPIQTypeGet to:itemElement.jid service:service];
		[featureQuery setDelegate:self];
		[featureQuery send];
	}
	return self;
}

-(void)dealloc
{
	[itemElement release];
	[featureQuery release];
	
	[service release];
	
	[super dealloc];
}

#pragma mark Props
- (XMPPJID *)jid
{
	return itemElement.jid;
}

#pragma mark Features
- (NSArray *)features
{
	return [[featureQuery features] allObjects];
}

- (BOOL)hasFeatureWithName:(NSString *)feature
{
	return [featureQuery hasFeatureWithName:feature];
}

#pragma mark XMPPInfoQuery Delegate Methods
- (void)infoQueryDidReceiveResult:(NSNotification *)note
{
}

- (void)infoQueryDidReceiveError:(NSNotification *)note
{
}

@end
