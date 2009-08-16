//
//  An InfoQuery for http://jabber.org/protocol/disco#info
//  XEP-0030

#import "XMPPInfoQuery.h"

@interface XMPPDiscoInfoInfoQuery : XMPPInfoQuery

@property (nonatomic, readwrite, copy) NSString *node;

+ (BOOL)stanzaHasDiscoInfoIQ:(XMPPStanza *)aStanza;

- (NSSet *)identities;	// Set of XMPPDiscoInfoIdentityElement
- (void)setIdentities:(id <NSFastEnumeration>)identities;

- (NSSet *)features;	// Set of XMPPDiscoInfoFeatureElement
- (void)setFeatures:(id <NSFastEnumeration>)features;

- (BOOL)hasFeatureWithName:(NSString *)feature;

@end
