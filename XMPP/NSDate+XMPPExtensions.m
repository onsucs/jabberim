#import "NSDate+XMPPExtensions.h"


@implementation NSDate (XMPPExtensions)


// XEP-0082 XMPP Date and Time Profiles
// FIXME: This is too tolerant. For many strings it will return a nonsense time when it should return nil
+ (NSDate *)dateWithXMPPDateString:(NSString *)dateString
{

	// Here are the possible formats:
	//		2009-06-16T09:58:00Z
	//		2009-06-16T05:58:00-04:00
	//		20090616T095800
	
	NSDate *date = nil;

	if ([dateString length] == 15)
	{
		// Compatibility format (section 4)
		// 20090616T095800
		
		NSDateComponents *dc = [[NSDateComponents alloc] init];
		[dc setYear:[[dateString substringToIndex:4] integerValue]];
		[dc setMonth:[[dateString substringWithRange:NSMakeRange(4, 2)] integerValue]];
		[dc setDay:[[dateString substringWithRange:NSMakeRange(6, 2)] integerValue]];
		[dc setHour:[[dateString substringWithRange:NSMakeRange(9, 2)] integerValue]];
		[dc setMinute:[[dateString substringWithRange:NSMakeRange(11, 2)] integerValue]];
		[dc setSecond:[[dateString substringWithRange:NSMakeRange(13, 2)] integerValue]];
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
		date = [gregorian dateFromComponents:dc];
		[dc release];
		[gregorian release];
	}
	else if ([dateString length] == 20)
	{
		// Zulu format
		// 2009-06-16T09:58:00Z
		NSDateComponents *dc = [[NSDateComponents alloc] init];
		[dc setYear:[[dateString substringToIndex:4] integerValue]];
		[dc setMonth:[[dateString substringWithRange:NSMakeRange(5, 2)] integerValue]];
		[dc setDay:[[dateString substringWithRange:NSMakeRange(8, 2)] integerValue]];
		[dc setHour:[[dateString substringWithRange:NSMakeRange(11, 2)] integerValue]];
		[dc setMinute:[[dateString substringWithRange:NSMakeRange(14, 2)] integerValue]];
		[dc setSecond:[[dateString substringWithRange:NSMakeRange(17, 2)] integerValue]];
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
		date = [gregorian dateFromComponents:dc];
		[dc release];
		[gregorian release];
	}
	else if ([dateString length] == 25)
	{
		// Offset format
		// 2009-06-16T05:58:00-04:00
		NSDateComponents *dc = [[NSDateComponents alloc] init];
		[dc setYear:[[dateString substringToIndex:4] integerValue]];
		[dc setMonth:[[dateString substringWithRange:NSMakeRange(5, 2)] integerValue]];
		[dc setDay:[[dateString substringWithRange:NSMakeRange(8, 2)] integerValue]];
		[dc setHour:[[dateString substringWithRange:NSMakeRange(11, 2)] integerValue]];
		[dc setMinute:[[dateString substringWithRange:NSMakeRange(14, 2)] integerValue]];
		[dc setSecond:[[dateString substringWithRange:NSMakeRange(17, 2)] integerValue]];
		
		NSInteger sign = ([dateString characterAtIndex:19] == '-') ? -1 : 1;
		NSInteger hourOffset = [[dateString substringWithRange:NSMakeRange(20, 2)] integerValue];
		NSInteger minuteOffset = [[dateString substringFromIndex:23] integerValue];
		NSInteger totalSecondsOffset = sign * (hourOffset * 60 * 60 + minuteOffset * 60);
		
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:totalSecondsOffset]];
		date = [gregorian dateFromComponents:dc];
		[dc release];
		[gregorian release];
	}
	else
	{
		NSLog(@"Bad date: %@", dateString);
	}
	
	return date;
}

- (NSString *)xmppDateString
{
	// 2009-06-16T09:58:00Z
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];	
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	return [dateFormatter stringFromDate:self];
}

@end
