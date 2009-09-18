//
//  JIMGroup.h
//  JabberIM
//
//  Created by Roland Moers on 18.09.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

@interface JIMGroup : NSObject {
	NSString *name;
	NSMutableArray *users;
}

@property (readonly) NSString *name; //Maybe rw in future
@property (readonly) NSMutableArray *users;

- (id)initWithName:(NSString *)name;

- (void)addUser:(XMPPUser *)newUser;
- (void)removeUser:(XMPPUser *)oldUser;

- (NSComparisonResult)compareByName:(JIMGroup *)another;
- (NSComparisonResult)compareByName:(JIMGroup *)another options:(NSStringCompareOptions)mask;

@end
