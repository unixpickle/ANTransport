//
//  ANTransportIdentity.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportConnector.h"

@protocol ANTransportIdentity <NSObject, NSCopying>

- (id<ANTransportConnector>)generateConnector;

- (BOOL)isEqualToIdentity:(id)identity;

- (NSString *)deviceName;
- (NSString *)deviceType;
- (UInt8)flags;

@end
