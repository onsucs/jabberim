#import "XMPPElement.h"

@implementation XMPPElement
@synthesize xmlElement = _xmlElement;

- (id)initWithXMLElement:(NSXMLElement *)anElement
{
	if (anElement == nil)
	{
		return nil;
	}
	
	self = [super init];
	if (self != nil)
	{
		self.xmlElement = anElement;
	}
	return self;
}

- (void) dealloc
{
	[_xmlElement release]; _xmlElement = nil;
	[super dealloc];
}

@end
