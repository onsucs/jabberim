//
//  <feature/> element of XMPPDiscoInfoInfoQuery. XEP-0030 11.1

#import "XMPPElement.h"

@interface XMPPDiscoInfoFeatureElement : XMPPElement

- (id)initWithName:(NSString *)name;

@property (nonatomic, readwrite, copy) NSString *name;

@end
