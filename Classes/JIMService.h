//
//  JIMService.h
//  JabberIM
//
//  Created by Roland Moers on 10.09.09.
//  Copyright 2009 Roland Moers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

@interface JIMService : NSObject {
	XMPPDiscoItemsItemElement *itemElement;
	XMPPDiscoInfoInfoQuery *featureQuery;
	
	XMPPService *service;
}

#pragma mark Init
- (id)initWithDiscoItemsItem:(XMPPDiscoItemsItemElement *)discoItemsItem service:(XMPPService *)xmppService;

#pragma mark Props
- (XMPPJID *)jid;

#pragma mark Features
- (NSArray *)features;
- (BOOL)hasFeatureWithName:(NSString *)feature;

@end
