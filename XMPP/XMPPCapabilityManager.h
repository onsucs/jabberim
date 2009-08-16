//
//  XMPPCapabilityManager.h
//  Manages capabilities for all known resources (including us)
//  XEP-0115
//

#import "XMPPManager.h"

@interface XMPPCapabilityManager : XMPPManager
{
	@private
	NSMutableDictionary *_infoForNode;	// node(with verString) => XMPPDiscoInfoInfoQuery
	NSMutableSet *_queries;
	NSMutableSet *_myIdentities;
	NSMutableSet *_myFeatures;
}

+ (XMPPCapabilityManager *)sharedManager;

- (void)addFeature:(NSString *)feature;	// FIXME: Move to services; not all services have the same capabilities

@end
