#import <Foundation/Foundation.h>


@interface NSDate (XMPPExtensions)
+ (NSDate *)dateWithXMPPDateString:(NSString *)dateString;
- (NSString *)xmppDateString;
@end
