//
//  ANTCPTransportIdentity.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportIdentity.h"

@interface ANTCPTransportIdentity : NSObject <ANTransportIdentity>

@property (nonatomic, strong) NSString * deviceName;
@property (nonatomic, strong) NSString * deviceType;
@property (readwrite) UInt8 flags;
@property (readonly) NSDictionary * addresses;

+ (ANTCPTransportIdentity *)localIdentity:(UInt16)port;

- (id)initWithData:(NSData *)data;
- (NSData *)encode;

@end
