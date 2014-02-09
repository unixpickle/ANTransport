//
//  ANTCPTransportScanner.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTCPTransportScanner.h"

@interface ANTCPTransportScanner (Private)

- (void)listenOnIPv4;
- (void)listenOnIPv6;

- (void)readPackets:(NSNumber *)theFd;
- (void)timeoutClients;

@end

@implementation ANTCPTransportScanner

- (id)initWithPort:(UInt16)aPort {
    if ((self = [super init])) {
        port = aPort;
    }
    return self;
}

- (BOOL)start {
    if (![super start]) return NO;
    
    lastSeens = [[NSMutableDictionary alloc] init];
    [self listenOnIPv4];
    [self listenOnIPv6];
    
    timeoutLoop = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timeoutClients)
                                                 userInfo:nil repeats:YES];
    
    return YES;
}

- (void)stop {
    if (!self.open) return;
    [super stop];
    
    [thread4 cancel];
    [thread6 cancel];
    if (fd4 >= 0) close(fd4);
    if (fd6 >= 0) close(fd6);
    [timeoutLoop invalidate];
}

#pragma mark - Overridden -

- (void)_handleFailed:(NSError *)error {
    [thread4 cancel];
    [thread6 cancel];
    if (fd4 >= 0) close(fd4);
    if (fd6 >= 0) close(fd6);
    [timeoutLoop invalidate];
    [super _handleFailed:error];
}

- (void)_handleIdentity:(id<ANTransportIdentity>)identity {
    NSAssert([(NSObject *)identity conformsToProtocol:@protocol(NSCopying)], @"identity must be copyable");
    lastSeens[(id<NSCopying>)identity] = [NSDate date];
    [super _handleIdentity:identity];
}

#pragma mark - Private -

- (void)listenOnIPv4 {
    struct sockaddr_in addr;
    int broadcast = 1;
    fd4 = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (fd4 < 0) return;
    
    setsockopt(fd4, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;
    if (bind(fd4, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd4);
        return;
    }
    
    thread4 = [[NSThread alloc] initWithTarget:self
                                      selector:@selector(readPackets:)
                                        object:@(fd4)];
    [thread4 start];
}

- (void)listenOnIPv6 {
    int broadcast = 1;
    struct sockaddr_in6 addr6;
    struct in6_addr theAddr = IN6ADDR_ANY_INIT;
    fd6 = socket(PF_INET6, SOCK_DGRAM, IPPROTO_UDP);
    if (fd6 < 0) return;
    
    setsockopt(fd6, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    addr6.sin6_addr = theAddr;
    if (bind(fd6, (struct sockaddr *)&addr6, sizeof(addr6)) < 0) {
        close(fd6);
        return;
    }
    
    thread6 = [[NSThread alloc] initWithTarget:self
                                      selector:@selector(readPackets:)
                                        object:@(fd6)];
    [thread6 start];
}

- (void)readPackets:(NSNumber *)theFd {
    while (YES) {
        @autoreleasepool {
            char buf[4096];
            ssize_t result = recvfrom(theFd.intValue, buf, sizeof(buf), 0, NULL, NULL);
            if ([[NSThread currentThread] isCancelled]) return;
            
            if (result < 0) {
                if (errno == EINTR) continue;
                NSError * error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
                [self performSelectorOnMainThread:@selector(_handleFailed:)
                                       withObject:error waitUntilDone:NO];
                return;
            } else if (result == 0) continue;
            
            // parse the packet here
            NSData * data = [NSData dataWithBytes:buf length:result];
            ANTCPTransportIdentity * identity = [[ANTCPTransportIdentity alloc] initWithData:data];
            if (identity) {
                [self performSelectorOnMainThread:@selector(_handleIdentity:)
                                       withObject:identity waitUntilDone:NO];
            }
        }
    }
}

- (void)timeoutClients {
    NSArray * keys = [lastSeens allKeys];
    NSDate * now = [NSDate date];
    for (id<ANTransportIdentity> identity in keys) {
        if ([now timeIntervalSinceDate:lastSeens[identity]] >= kANTCPTransportScannerTimeout) {
            [self _handleIdentityGone:lastSeens[identity]];
            [lastSeens removeObjectForKey:identity];
        }
    }
}

@end
