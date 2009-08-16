//
//  An abstract element that holds an NSXMLElement
//
#import <Foundation/Foundation.h>
#import "NSXMLElementAdditions.h"

@interface XMPPElement : NSObject
{
	@private
	NSXMLElement *_xmlElement;
}

- (id)initWithXMLElement:(NSXMLElement *)anElement;

@property (nonatomic, readwrite, retain, setter=setXMLElement:) NSXMLElement *xmlElement;

@end
