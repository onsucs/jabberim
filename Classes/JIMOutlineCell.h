#import <Cocoa/Cocoa.h>

@interface JIMOutlineCell : NSCell 
{
	NSString *title;
	NSString *subtitle;
	NSImage *image;
	NSImage *statusImage;
	
	BOOL enabled;
}

@property (assign, readwrite) NSString *title;
@property (assign, readwrite) NSString *subtitle;
@property (assign, readwrite) NSImage* image;
@property (assign, readwrite) NSImage* statusImage;
@property (assign, readwrite) BOOL enabled;

@end
