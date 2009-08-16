//
//  XMPPRoomOccupant.h
//  An occupant of an XMPPRoom
//

extern NSString* const XMPPRoomOccupantDidLeaveRoomNotification;

@class XMPPResource;

@interface XMPPRoomOccupant : NSObject
{
	XMPPResource *_resource;
}

- (XMPPRoomOccupant *)initWithResource:(XMPPResource *)aResource;

@property (nonatomic, readonly) NSString *name;

@end

@interface NSNotificationCenter (XMPPRoomOccupant)
- (void)postNotificationName:(NSString *)name object:(id)object roomOccupant:(XMPPRoomOccupant *)occupant;
@end

@interface NSNotification (XMPPRoomOccupant)
- (XMPPRoomOccupant *)roomOccupant;
@end
