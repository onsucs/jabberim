//
//  JIMGroup.m
//  JabberIM
//
//  Created by Roland Moers on 18.09.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import "JIMGroup.h"

@implementation JIMGroup

@synthesize name;
@synthesize users;

#pragma mark Init and Dealloc
- (id)initWithName:(NSString *)newName
{
	if((self = [super init]))
	{
		users = [[NSMutableArray alloc] init];
		name = newName;
	}
	return self;
}

- (void)dealloc
{	
	[users release];
	
	[super dealloc];
}

#pragma mark Add/Remove users
- (void)addUser:(XMPPUser *)newUser
{
	if([users indexOfObject:newUser] == NSNotFound)
		[users addObject:newUser];
}

- (void)removeUser:(XMPPUser *)oldUser
{
	[users removeObject:oldUser];
}

#pragma mark Comparison Methods
- (NSComparisonResult)compareByName:(JIMGroup *)another
{
	return [self compareByName:another options:0];
}

- (NSComparisonResult)compareByName:(JIMGroup *)another options:(NSStringCompareOptions)mask
{
	if([self.name isEqualToString:@"Offline"])
		return NSOrderedDescending;
	else if([self.name isEqualToString:@"Not grouped"])
	{
		if([another.name isEqualToString:@"Offline"])
			return NSOrderedAscending;
		else
			return NSOrderedDescending;
	}
	
	return [self.name compare:another.name options:mask];
}

@end
