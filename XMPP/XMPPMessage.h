//
//  XMPPMessage.h
//  Abstract <message/>
//

#import <Foundation/Foundation.h>
#import "XMPPMessageStanza.h"

@class XMPPService;
@class XMPPJID;

@interface XMPPMessage : NSObject <NSCoding>
{
	@private
	XMPPService *_service;
	XMPPMessageStanza *_stanza;
	NSDate *_date;
}
@property (nonatomic, readonly, retain) XMPPMessageStanza *stanza;
@property (nonatomic, readonly, assign) XMPPService *service;
@property (nonatomic, readwrite, copy)	XMPPJID *fromJID;
@property (nonatomic, readwrite, copy)	XMPPJID *toJID;
@property (nonatomic, readwrite, copy)	NSString *body;
@property (nonatomic, readwrite, retain) NSDate *date;	// Nominal time message was sent

- (id)initWithMessageStanza:(XMPPMessageStanza *)stanza service:(XMPPService *)service;	// Designated initializer
- (id)initWithFrom:(XMPPJID *)aFromJID to:(XMPPJID *)aToJID type:(XMPPMessageType)aType service:(XMPPService *)aService;
- (id)initWithTo:(XMPPJID *)aToJID type:(XMPPMessageType)aType service:(XMPPService *)aService;

- (void)send;

- (BOOL)isFromMe;

@end
