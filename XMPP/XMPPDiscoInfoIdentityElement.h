//
//  <identity/> element of XMPPDiscoInfoInfoQuery. XEP-0030 11.1

#import "XMPPElement.h"

@interface XMPPDiscoInfoIdentityElement : XMPPElement

- (id)initWithCategory:(NSString *)category name:(NSString *)name type:(NSString *)type;

@property (nonatomic, readwrite, copy) NSString *category;
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSString *type;
@end
