//  XMPPStanza.h
//  An XML Stanza as defined in RFC 3920 section 9
//  This includes both client and server stanzas of types message, presence and iq.
//  Server and client stanzas are not treated separately by XMPPStanza or its subclasses.

#import <Foundation/Foundation.h>
#import "NSXMLElementAdditions.h"
#import "DDXML.h"

@class XMPPJID;

///////////////////////////////////////////////
@interface XMPPStanza : NSXMLElement <NSCoding>

- (id)initWithXMLElement:(NSXMLElement *)element;
- (id)initWithName:(NSString *)name fromJID:(XMPPJID *)from toJID:(XMPPJID *)to;

// These aren't really defined in RFC 3920. They're from RFC 3921 B.1/B.2.
// But they are ubiquitous, and should be expected in any future subclasses.
// 'type' is also ubiquitous, but has different types (enums) for each subclass, so is not handled here.
@property (nonatomic, readwrite, copy)		NSString *uniqueIdentifier;	// <xs:attribute name='id' type='xs:NMTOKEN' use='optional'/>
@property (nonatomic, readwrite, retain)	XMPPJID *fromJID;			// <xs:attribute name='from' type='xs:string' use='optional'/>
@property (nonatomic, readwrite, retain)	XMPPJID *toJID;				// <xs:attribute name='to' type='xs:string' use='optional'/>
@property (nonatomic, readwrite, copy)		NSString *language;			// <xs:attribute ref='xml:lang' use='optional'/> (RFC 3066)
@property (nonatomic, readwrite, retain)	NSDate *delayDate;			// <xs:attribute name='stamp' type='xs:dateTime' use='required'/> (XEP-203 Delayed Delivery)

@end

//////////////////////////////////////
@interface NSNotification (XMPPStanza)
- (XMPPStanza *)stanza;
@end

////////////////////////////////////////////
@interface NSNotificationCenter (XMPPStanza)
- (void)postNotificationName:(NSString *)notificationName object:(id)notificationSender stanza:(XMPPStanza *)stanza;
@end

@interface NSNotificationQueue (XMPPStanza)
- (void)enqueueNotificationName:(NSString *)notificationName object:(id)notificationSender stanza:(XMPPStanza *)stanza;
@end