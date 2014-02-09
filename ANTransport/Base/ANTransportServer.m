//
//  ANTransportServer.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportServer.h"

@implementation ANTransportServer

- (id)initWithDeviceName:(NSString *)device type:(NSString *)type flags:(UInt8)flags {
    if ((self = [super init])) {
        _deviceName = device;
        _deviceType = type;
        _flags = flags;
    }
    return self;
}

- (BOOL)start {
    if (self.isOpen) return NO;
    return _open = YES;
}

- (void)stop {
    _open = NO;
}

- (void)_handleClient:(id<ANTransport>)transport {
    if (!self.open) return;
    [self.delegate transportServer:self gotTransport:transport];
}

- (void)_handleError:(NSError *)error {
    if (!self.open) return;
    _open = NO;
    [self.delegate transportServer:self failedWithError:error];
}

@end
