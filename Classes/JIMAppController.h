//
//  JIMAppController.h
//  JabberIM
//
//  Created by Roland Moers on 09.08.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JIMAccountManager.h>

@interface JIMAppController : NSObject {
	IBOutlet NSUserDefaultsController *userDefaultsController;
	IBOutlet JIMAccountManager *accountManager;
}

@end
