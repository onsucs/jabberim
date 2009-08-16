//
// XMPPService.h
// A connection to an RFC 3920 XMPP Core service.
//

#import <Foundation/Foundation.h>
#import "XMPPPresenceStanza.h"

//
// Notifications
//
extern NSString* const XMPPServiceDidBeginConnectNotification;
extern NSString* const XMPPServiceDidConnectNotification;
extern NSString* const XMPPServiceDidFailConnectNotification;
extern NSString* const XMPPServiceDidDisconnectNotification;
extern NSString* const XMPPServiceDidRegisterNotification;
extern NSString* const XMPPServiceDidFailRegisterNotification;
extern NSString* const XMPPServiceDidAuthenticateNotification;
extern NSString* const XMPPServiceDidFailAuthenticateNotification;
extern NSString* const XMPPServiceDidReceiveTCPErrorNotification;
extern NSString* const XMPPServiceDidSendStanzaNotification;
extern NSString* const XMPPServiceDidFailSendStanzaNotification;
extern NSString* const XMPPServiceDidReceiveMessageStanzaNotification;
extern NSString* const XMPPServiceDidReceivePresenceStanzaNotification;
extern NSString* const XMPPServiceDidReceiveIQStanzaNotification;

@class XMPPStream;
@class XMPPJID;
@class XMPPResource;
@class XMPPStanza;

@interface XMPPService : NSObject
{
	@private
	XMPPStream *_stream;
	
	NSImage *_serviceIcon;
	NSString *_domain;
	UInt16 _port;
	NSString *_password;

	struct
	{
		unsigned int usesOldStyleSSL:1;
		unsigned int autoLogin:1;
		unsigned int allowsPlaintextAuth:1;
		unsigned int autoRoster:1;
		unsigned int autoPresence:1;
		unsigned int autoReconnect:1;
		unsigned int shouldReconnect:1;
	} _serviceFlags;

	XMPPPriority _priority;	// -127 to 127
	
	XMPPResource *_myResource;
	
	NSMutableDictionary *_pendingStanzas;	// Stanza for Hash (NSNumber) of ID
}

- (id)initWithDomain:(NSString *)domain port:(UInt16)port jid:(XMPPJID *)jid password:(NSString *)password;
- (void)addObserverForRespondingNotifications:(id)observer;

@property (nonatomic, readonly)	NSString *uniqueIdentifier;

//
// Basic immutable information about the Service
//
@property (nonatomic, readonly, retain)	NSImage *serviceIcon;
@property (nonatomic, readonly, copy)	NSString *domain;
@property (nonatomic, readonly, assign)	UInt16 port;
@property (nonatomic, readonly, retain)	XMPPResource *myResource;
@property (nonatomic, readonly)			XMPPJID *myJID;	// Convenience access to the JID of myResource.

//
// Connection configuration (can't be changed after connecting)
//
@property (nonatomic, readwrite, assign) BOOL validatesCertificateChain;
@property (nonatomic, readwrite, assign) BOOL allowsSelfSignedCertificates;
@property (nonatomic, readwrite, assign) BOOL allowsSSLHostNameMismatch;
@property (nonatomic, readwrite, assign) BOOL allowsPlaintextAuth;
@property (nonatomic, readwrite, assign) BOOL usesOldStyleSSL;
@property (nonatomic, readwrite, assign) BOOL autoLogin;		// Automatically authenticate after connecting? (default:YES)
@property (nonatomic, readwrite, assign) BOOL autoReconnect;	// Automatically reconnect if we drop connection? (default:YES)

//
// Service features
//
@property (nonatomic, readonly) BOOL supportsInBandRegistration;
@property (nonatomic, readonly) BOOL supportsPlainAuthentication;
@property (nonatomic, readonly) BOOL supportsDigestMD5Authentication;

//
// Changable configuration
//
@property (nonatomic, readwrite, assign) XMPPPriority priority;	// Default:1

//
// Connection status
// NOTE: There are states between connected and disconnected. Both can be NO.
@property (nonatomic, readonly) BOOL isDisconnected;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isSecure;
@property (nonatomic, readonly) BOOL isAuthenticated;

//
// Connection actions
//
- (void)connect;	// Based on connection configuration, may automatically progress.
- (void)registerUser;
- (void)authenticateUser;
- (void)goOnline;
- (void)goOffline;
- (void)disconnect;

//
// Stanza actions
//
- (void)sendStanza:(XMPPStanza *)stanza;
- (void)setShow:(NSString *)show andStatus:(NSString *)status;

@end

@protocol XMPPServiceDelegate <NSObject>
@optional
- (void)serviceDidBeginConnect:(NSNotification *)note;
- (void)serviceDidConnect:(NSNotification *)note;
- (void)serviceDidFailConnect:(NSNotification *)note;
- (void)serviceDidDisconnect:(NSNotification *)note;
- (void)serviceDidRegister:(NSNotification *)note;
- (void)serviceDidFailRegister:(NSNotification *)note;
- (void)serviceDidAuthenticate:(NSNotification *)note;
- (void)serviceDidFailAuthenticate:(NSNotification *)note;
- (void)serviceDidReceiveTCPError:(NSNotification *)note;
- (void)serviceDidSendStanza:(NSNotification *)note;
- (void)serviceDidFailSendStanza:(NSNotification *)note;
- (void)serviceDidReceiveMessageStanza:(NSNotification *)note;
- (void)serviceDidReceivePresenceStanza:(NSNotification *)note;
- (void)serviceDidReceiveIQStanza:(NSNotification *)note;
@end

