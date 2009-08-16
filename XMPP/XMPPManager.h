//
//  XMPPManager.h
//  Abstract class for things that need to manage objects for all XMPPServices
//
#import <Foundation/Foundation.h>

@class XMPPService;

@interface XMPPManager : NSObject
{
	@private
	NSMutableSet *_services;
}

@property (nonatomic, readonly) NSMutableSet *services;

- (void)addService:(XMPPService *)aService;
- (void)removeService:(XMPPService *)aService;

@end
