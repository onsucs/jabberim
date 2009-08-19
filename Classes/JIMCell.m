#import "JIMCell.h"

@implementation JIMCell

@synthesize title;
@synthesize subtitle;
@synthesize image;
@synthesize statusImage;
@synthesize enabled;

- (void)drawInteriorWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView
{
	
	// Inset the cell frame to give everything a little horizontal padding
	NSRect		anInsetRect = NSInsetRect(theCellFrame,10,0);
	
	// Flip the icon because the entire cell has a flipped coordinate system
	[image setFlipped:YES];
	[statusImage setFlipped:YES];
	
	// get the size of the icons for layout
	NSSize		imageSize = NSMakeSize(25, 25);
	NSSize statusImageSize = NSMakeSize(12, 12);
	
	// Make attributes for our strings
	NSMutableParagraphStyle * aParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[aParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// Title attributes: system font, 14pt, black, truncate tail
	NSMutableDictionary * aTitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
											 [NSColor blackColor],NSForegroundColorAttributeName,
											 [NSFont systemFontOfSize:13.0],NSFontAttributeName,
											 aParagraphStyle, NSParagraphStyleAttributeName,
											 nil] autorelease];
											
	NSSize aTitleSize = [title sizeWithAttributes:aTitleAttributes];
	
	// subTitle attributes: system font, 14pt, black, truncate tail
	NSMutableDictionary * aSubtitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
											   [NSColor grayColor],NSForegroundColorAttributeName,
											   [NSFont systemFontOfSize:9.0],NSFontAttributeName,
											   aParagraphStyle, NSParagraphStyleAttributeName,
											   nil] autorelease];
	
	NSSize aSubtitleSize = [title sizeWithAttributes:aTitleAttributes];
	
	
	// Make the layout boxes for all of our elements - remember that we're in a flipped coordinate system when setting the y-values
	// Vertical padding between the lines of text
	float		aVerticalPadding = 5.0;
	
	// Horizontal padding between icon and text
	float		aHorizontalPadding = 10.0;
	
	// Icon box: center the icon vertically inside of the inset rect
	NSRect		anIconBox = NSMakeRect(anInsetRect.origin.x,
									   anInsetRect.origin.y + anInsetRect.size.height*.5 - imageSize.height*.5,
									   imageSize.width,
									   imageSize.height);
	
	// Status Icon box: center the icon vertically inside of the inset rect
	NSRect		anStatusIconBox = NSMakeRect(theCellFrame.size.width - 15,
									   anInsetRect.origin.y + anInsetRect.size.height*.5 - statusImageSize.height*.5,
									   statusImageSize.width,
									   statusImageSize.height);
	
	NSRect aTitleBox;
	NSRect aSubtitleBox;
	
	if(subtitle)
	{
		if(statusImage)
		{
			float		aCombinedHeight = aTitleSize.height + aVerticalPadding;
			
			aTitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
								   anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight*.5 - 3,
								   anInsetRect.size.width - imageSize.width*2 - aHorizontalPadding,
								   aCombinedHeight);
			
			float		aCombinedHeight2 = aSubtitleSize.height + aVerticalPadding;
			
			aSubtitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
									  anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight2*.5 + 13,
									  anInsetRect.size.width - imageSize.width*2 - aHorizontalPadding,
									  aCombinedHeight2);
		}
		else
		{
			float		aCombinedHeight = aTitleSize.height + aVerticalPadding;
			
			aTitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
								   anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight*.5 - 3,
								   anInsetRect.size.width - aHorizontalPadding - 5,
								   aCombinedHeight);
			
			float		aCombinedHeight2 = aSubtitleSize.height + aVerticalPadding;
			
			aSubtitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
									  anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight2*.5 + 13,
									  anInsetRect.size.width - aHorizontalPadding - 5,
									  aCombinedHeight2);
		}
		
	}
	else
	{
		if(statusImage)
		{
			float		aCombinedHeight = aTitleSize.height + aVerticalPadding;
			
			aTitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
								   anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight*.5 + 2,
								   anInsetRect.size.width - imageSize.width*2 - aHorizontalPadding,
								   aCombinedHeight);
		}
		else
		{
			float		aCombinedHeight = aTitleSize.height + aVerticalPadding;
			
			aTitleBox = NSMakeRect(anIconBox.origin.x + anIconBox.size.width + aHorizontalPadding,
								   anInsetRect.origin.y + anInsetRect.size.height*.5 - aCombinedHeight*.5 + 2,
								   anInsetRect.size.width - aHorizontalPadding - 5,
								   aCombinedHeight);
		}
	}
	
	if([self isHighlighted])
		// if the cell is highlighted, draw the text white or gray (if not enabled)
		if(enabled)
		{
			[aTitleAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			[aSubtitleAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		}
		else
		{
			[aTitleAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
			[aSubtitleAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		}
	else
	{
		// if the cell is not highlighted, draw the title black or gray (if not enabled)
		if(enabled)
		{
			[aTitleAttributes setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
			[aSubtitleAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		}
		else
		{
			[aTitleAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
			[aSubtitleAttributes setValue:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		}
	}
	
	
	// Draw the image and title
	[image drawInRect:anIconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[statusImage drawInRect:anStatusIconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[title drawInRect:aTitleBox withAttributes:aTitleAttributes];
	if(subtitle)
		[subtitle drawInRect:aSubtitleBox withAttributes:aSubtitleAttributes];
	
	[image setFlipped:NO];
	[statusImage setFlipped:NO];
}

@end
