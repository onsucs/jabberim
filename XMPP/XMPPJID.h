//
// A Jabber ID (JID)
//
#import <Foundation/Foundation.h>
#import "DDXML.h"

@interface XMPPJID : NSObject <NSCoding, NSCopying>
{
	@private
	NSString *_user;
	NSString *_domain;
	NSString *_resource;
}
@property (nonatomic, readonly) NSString *user;
@property (nonatomic, readonly) NSString *domain;
@property (nonatomic, readonly) NSString *resource;

+ (XMPPJID *)jidWithString:(NSString *)jidStr;
+ (XMPPJID *)jidWithString:(NSString *)jidStr resource:(NSString *)resource;
+ (XMPPJID *)jidWithUser:(NSString *)user domain:(NSString *)domain resource:(NSString *)resource;

- (XMPPJID *)bareJID;	// A JID without the Resource
- (BOOL)isBareJID;

- (NSString *)bareString;
- (NSString *)fullString;

@end
