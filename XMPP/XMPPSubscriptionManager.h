//
//  XMPPSubscriptionManager.h
//  Manages subscription requests from other users

#import "XMPPManager.h"

@interface XMPPSubscriptionManager : XMPPManager
{
	NSMutableSet *_requests;
}

+ (XMPPSubscriptionManager *)sharedManager;

@end
