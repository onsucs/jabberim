//  NSNotificationCenter+RNDelegate.m
//

#import "NSNotificationCenter+RNDelegate.h"
#import <objc/runtime.h>

@implementation NSNotificationCenter (RNDelegate)

SEL RNSelectorForNotificationNameWithPrefix(NSString *notificationName, NSString *prefix)
{
	NSMutableString *methodName = [notificationName mutableCopy];
	NSRange prefixRange = [methodName rangeOfString:prefix options:NSAnchoredSearch];
	NSCAssert2(prefixRange.location == 0, @"Notification (%@) must start with prefix (%@).", notificationName, prefix);
	[methodName deleteCharactersInRange:prefixRange];

	NSString *firstCharacter = [methodName substringToIndex:1];
	[methodName replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstCharacter lowercaseString]];
	
	NSRange suffixRange = [methodName rangeOfString:@"Notification" options:NSAnchoredSearch|NSBackwardsSearch];
	NSCAssert1(prefixRange.location != NSNotFound, @"Notification (%@) must end with 'Notification'.", notificationName);
	[methodName deleteCharactersInRange:suffixRange];
	
	[methodName appendString:@":"];
	
	SEL selector = NSSelectorFromString(methodName);
	
	[methodName release];
	return selector;
}

- (void)addObserver:(id)notificationObserver forRespondingNotificationNames:(id<NSFastEnumeration>)notificationNames prefix:(NSString *)prefix object:(id)notificationSender
{
	for (NSString *notificationName in notificationNames)
	{
		SEL selector = RNSelectorForNotificationNameWithPrefix(notificationName, prefix);
		if ([notificationObserver respondsToSelector:selector])
		{
			[self addObserver:notificationObserver selector:selector name:notificationName object:notificationSender];
		}
	}
}

@end