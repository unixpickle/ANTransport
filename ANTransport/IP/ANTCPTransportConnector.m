//
//  ANTCPTransportConnector.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTCPTransportConnector.h"

@interface ANTCPTransportConnector (Private)

- (void)attemptConnection:(NSDictionary *)info;
- (void)handleFileDescriptor:(NSNumber *)anFd;

@end

@implementation ANTCPTransportConnector

- (void)start {
    if (open) return;
    open = YES;
    threads = [NSMutableArray array];
    
    // create a connect thread per each IP/port pair
    for (NSString * addr in self.identity.addresses) {
        NSDictionary * info = @{@"port": self.identity.addresses[addr],
                                @"addr": addr};
        NSThread * theThread = [[NSThread alloc] initWithTarget:self
                                                       selector:@selector(attemptConnection:)
                                                         object:info];
        [threads addObject:theThread];
        [theThread start];
    }
}

- (void)cancel {
    if (!open) return;
    open = NO;
    for (NSThread * t in threads) [t cancel];
}

#pragma mark - Private -

- (void)attemptConnection:(NSDictionary *)info {
    @autoreleasepool {
        NSString * addrStr = info[@"addr"];
        int port = [info[@"port"] intValue];
        
        // attempt a connection
        struct hostent * host = gethostbyname([addrStr UTF8String]);
        int fd = -1;
        if (host->h_addrtype == AF_INET) {
            struct sockaddr_in addr;
            bzero(&addr, sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_port = htons(port);
            memcpy(&addr.sin_addr.s_addr, host->h_addr_list[0], sizeof(struct in_addr));
            fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
            if (fd < 0) return;
            if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
                close(fd);
                return;
            }
        } else if (host->h_addrtype == AF_INET6) {
            struct sockaddr_in6 addr;
            bzero(&addr, sizeof(addr));
            addr.sin6_family = AF_INET6;
            addr.sin6_port = htons(port);
            memcpy(&addr.sin6_addr, host->h_addr_list[0], sizeof(struct in6_addr));
            fd = socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);
            if (fd < 0) return;
            if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
                close(fd);
                return;
            }
        }
        if (![[NSThread currentThread] isCancelled]) {
            [self performSelectorOnMainThread:@selector(handleFileDescriptor:)
                                   withObject:@(fd)
                                waitUntilDone:NO];
        } else {
            close(fd);
        }
    }
}

- (void)handleFileDescriptor:(NSNumber *)anFd {
    if (!open) {
        close(anFd.intValue);
        return;
    }
    if (self.callback) {
        self.callback(nil, [[ANTCPTransport alloc] initWithFileDescriptor:anFd.intValue]);
    }
}

@end
