// Protected methods for XMPPInfoQuery

#import "XMPPInfoQuery.h"

@interface XMPPInfoQuery (Protected)
@property (nonatomic, readwrite, retain) XMPPIQStanza *stanza;
@property (nonatomic, readonly) NSXMLElement *query;
- (NSSet *)objectsOfClass:(Class)class forName:(NSString *)name;
@end
