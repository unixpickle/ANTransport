//
//  ANTCPTransportIdentity.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTCPTransportIdentity.h"
#import "ANTCPTransportConnector.h"

static NSData * readUnitlNULL(NSData * aData, NSData ** remaining);

@interface ANTCPTransportIdentity (Private)

- (id)initWithName:(NSString *)name type:(NSString *)type flags:(UInt8)flags addresses:(NSDictionary *)dict;

@end

@implementation ANTCPTransportIdentity

+ (ANTCPTransportIdentity *)localIdentity:(UInt16)port {
#if TARGET_OS_IPHONE
    NSString * devName = [[UIDevice currentDevice] name];
#else
    NSString * devName = [[NSHost currentHost] localizedName];
#endif
    NSString * devType = @"Objective-C";
    NSMutableDictionary * addrs = [NSMutableDictionary dictionary];
    for (NSString * addr in [[NSHost currentHost] addresses]) {
        addrs[addr] = @(port);
    }
    return [[ANTCPTransportIdentity alloc] initWithName:devName
                                                   type:devType
                                                  flags:port
                                              addresses:addrs];
}

- (id)initWithData:(NSData *)data {
    if ((self = [super init])) {
        NSData * remainingData = data;
        NSData * nameData = readUnitlNULL(data, &remainingData);
        NSData * typeData = readUnitlNULL(remainingData, &remainingData);
        if (!typeData || !nameData) return nil;
        _deviceName = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];
        _deviceType = [[NSString alloc] initWithData:typeData encoding:NSUTF8StringEncoding];
        
        if (!remainingData.length) return nil;
        _flags = *((const UInt8 *)remainingData.bytes);
        remainingData = [remainingData subdataWithRange:NSMakeRange(1, remainingData.length - 1)];
        
        NSMutableDictionary * mAddresses = [NSMutableDictionary dictionary];
        while (remainingData.length) {
            NSData * ipData = readUnitlNULL(remainingData, &remainingData);
            if (!ipData) return nil;
            NSString * addrStr = [[NSString alloc] initWithData:ipData encoding:NSUTF8StringEncoding];
            if (!addrStr) return nil;
            
            if (remainingData.length < 2) return nil;
            UInt16 portValue = htons(*((const UInt16 *)remainingData.bytes));
            
            [mAddresses setObject:@(portValue) forKey:addrStr];
            remainingData = [remainingData subdataWithRange:NSMakeRange(2, remainingData.length - 2)];
        }
        _addresses = [mAddresses copy];
    }
    return self;
}

- (NSData *)encode {
    NSMutableData * data = [NSMutableData data];
    UInt8 nullByte = 0;
    
    [data appendData:[self.deviceName dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:&nullByte length:1];
    [data appendData:[self.deviceType dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:&nullByte length:1];
    [data appendBytes:&_flags length:1];
    for (NSString * address in self.addresses) {
        int port = [self.addresses[address] intValue];
        UInt16 encodedPort = CFSwapInt16HostToBig(port);
        [data appendData:[address dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendBytes:&nullByte length:1];
        [data appendBytes:&encodedPort length:2];
    }
    return [data copy];
}

#pragma mark - Protocols -

- (id)copyWithZone:(NSZone *)zone {
    return [[self.class alloc] initWithName:self.deviceName
                                       type:self.deviceType
                                      flags:self.flags
                                  addresses:self.addresses];
}

- (BOOL)isEqualToIdentity:(id)identity {
    if (![identity isKindOfClass:[ANTCPTransportIdentity class]]) {
        return false;
    }
    ANTCPTransportIdentity * ident = (ANTCPTransportIdentity *)identity;
    return ident.flags == self.flags && [ident.deviceType isEqualToString:self.deviceType] &&
        [ident.deviceName isEqualToString:self.deviceName] &&
        [ident.addresses isEqualToDictionary:self.addresses];
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToIdentity:object];
}

- (id<ANTransportConnector>)generateConnector {
    ANTCPTransportConnector * connector = [[ANTCPTransportConnector alloc] init];
    connector.identity = self;
    return connector;
}

#pragma mark - Private -

- (id)initWithName:(NSString *)name type:(NSString *)type flags:(UInt8)flags addresses:(NSDictionary *)dict {
    if ((self = [super init])) {
        _deviceName = name;
        _deviceType = type;
        _flags = flags;
        _addresses = dict;
    }
    return self;
}

@end

static NSData * readUnitlNULL(NSData * aData, NSData ** remaining) {
    if (!aData) return nil;
    NSMutableData * result = [NSMutableData data];
    const char * bytes = (const char *)aData.bytes;
    for (int i = 0; i < aData.length; i++) {
        if (!bytes[i]) {
            *remaining = [aData subdataWithRange:NSMakeRange(i + 1, aData.length - (i + 1))];
            return result;
        }
        [result appendBytes:&bytes[i] length:1];
    }
    return nil;
}
