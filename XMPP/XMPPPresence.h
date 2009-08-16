//
//  XMPPPresence.h
//  Abstract <presence/>
//

#import <Foundation/Foundation.h>
#import "XMPPPresenceStanza.h"

@class XMPPService;

@interface XMPPPresence : NSObject
{
	@private
	XMPPService *_service;
	XMPPPresenceStanza *_stanza;
}

@property (nonatomic, readonly, assign) XMPPService *service;
@property (nonatomic, readonly, retain) XMPPPresenceStanza *stanza;
@property (nonatomic, readwrite, copy)	XMPPJID *fromJID;
@property (nonatomic, readwrite, copy)	XMPPJID *toJID;

- (id)initWithPresenceStanza:(XMPPPresenceStanza *)stanza service:(XMPPService *)service;	// Designated initializer

- (void)send;

@end
