//  XMPPInfoQuery.h
//  An abstract InfoQuery, mapped to a particular service, and providing notifications.

#import <Foundation/Foundation.h>
#import "XMPPIQStanza.h"

extern NSString* const XMPPInfoQueryDidReceiveResultNotification;
extern NSString* const XMPPInfoQueryDidReceiveErrorNotification;

@class XMPPService;
@class XMPPJID;

@interface XMPPInfoQuery : NSObject <NSCoding>
{
	@private
	id _delegate;
	XMPPService *_service;
	XMPPIQStanza *_stanza;
}

- (id)initWithType:(XMPPIQType)type to:(XMPPJID *)jid service:(XMPPService *)service;
- (id)initWithIQStanza:(XMPPIQStanza *)stanza service:(XMPPService *)service;
- (id)initWithResultForIQStanza:(XMPPIQStanza *)aStanza service:(XMPPService *)service;

@property (nonatomic, readwrite, assign) id delegate;
@property (nonatomic, readonly) XMPPJID *jid;
@property (nonatomic, readwrite, retain) XMPPService *service;
@property (nonatomic, readwrite, assign) XMPPIQType type;
@property (nonatomic, readwrite, retain) XMPPIQStanza *stanza;
		   
- (void)send;

@end

@protocol XMPPInfoQueryDelegate <NSObject>;
@optional
- (void)infoQueryDidReceiveError:(NSNotification *)note;
- (void)infoQueryDidReceiveResult:(NSNotification *)note;
@end
