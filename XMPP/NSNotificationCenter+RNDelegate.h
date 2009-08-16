//
//  NSNotificationCenter+RNDelegate.h
//  Automatically subscribe delegate to notifications it responds to

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (RNDelegate)
- (void)addObserver:(id)notificationObserver forRespondingNotificationNames:(id<NSFastEnumeration>)notificationNames prefix:(NSString *)prefix object:(id)notificationSender;
@end