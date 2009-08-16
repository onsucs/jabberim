//
//  XMPPRoomOwnerInfoQuery.m
//  Infoquery for http://jabber.org/protocol/muc#owner
//
//

#import "XMPPRoomOwnerInfoQuery.h"
#import "XMPPInfoQuery+Protected.h"
#import "XMPPRoom.h"

static NSString* const RoomOwnerNamespaceName = @"http://jabber.org/protocol/muc#owner";

@implementation XMPPRoomOwnerInfoQuery

- (id)initWithRoom:(XMPPRoom *)aRoom
{
	self = [super initWithType:XMPPIQTypeSet to:aRoom.jid service:aRoom.service];
	if (self != nil)
	{
		NSXMLElement *xElement = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
		[xElement addAttributeWithName:@"type" stringValue:@"submit"];
		[self.stanza addChild:[NSXMLElement elementWithName:@"query" xmlns:RoomOwnerNamespaceName]];
		[self.query addChild:xElement];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Protected methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSXMLElement *)query
{
	return [[self stanza] elementForName:@"query" xmlns:RoomOwnerNamespaceName];
}


@end
