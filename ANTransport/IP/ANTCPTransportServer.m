//
//  ANTCPTransportServer.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTCPTransportServer.h"

@interface ANTCPTransportServer (Private)

- (void)startIPv4Acceptor;
- (void)startIPv6Acceptor;
- (void)acceptMethod:(NSNumber *)fd;
- (void)broadcastInformation;

@end

@implementation ANTCPTransportServer

- (id)initWithPort:(UInt16)port broadcastPort:(UInt16)bcastPort flags:(UInt8)flags {
    ANTCPTransportIdentity * identity = [ANTCPTransportIdentity localIdentity:port];
    if ((self = [super initWithDeviceName:identity.deviceName
                                     type:identity.deviceType
                                    flags:flags])) {
        _port = port;
        _bcastPort = bcastPort;
    }
    return self;
}

- (BOOL)start {
    if (![super start]) return NO;
    
    broadcastTimer = [NSTimer scheduledTimerWithTimeInterval:kANTCPTransportServerHeartbeat
                                                      target:self
                                                    selector:@selector(broadcastInformation)
                                                    userInfo:nil repeats:YES];
    acceptThreads = [NSMutableArray array];
    
    // create UDP broadcaster
    udp4Broadcast = socket(AF_INET, SOCK_DGRAM, 0);
    udp6Broadcast = socket(AF_INET6, SOCK_DGRAM, 0);
    int broadcastEnable = 1;
    if (udp4Broadcast >= 0) {
        if (setsockopt(udp4Broadcast, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable)) < 0) {
            close(udp4Broadcast);
            if (udp6Broadcast >= 0) close(udp6Broadcast);
            return NO;
        }
    }
    if (udp6Broadcast >= 0) {
        if (setsockopt(udp6Broadcast, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable)) < 0) {
            close(udp6Broadcast);
            if (udp4Broadcast >= 0) close(udp4Broadcast);
            return NO;
        }
    }
    
    [self startIPv4Acceptor];
    [self startIPv6Acceptor];
    
    return YES;
}

- (void)stop {
    if (!self.isOpen) return;
    [super stop];
    
    [broadcastTimer invalidate];
    for (NSThread * th in acceptThreads) [th cancel];
    if (udp6Broadcast >= 0) close(udp6Broadcast);
    if (udp4Broadcast >= 0) close(udp4Broadcast);
    if (server4Socket >= 0) close(server4Socket);
    if (server6Socket >= 0) close(server6Socket);
}

- (void)_handleError:(NSError *)error {
    if (self.isOpen) {
        [broadcastTimer invalidate];
        for (NSThread * th in acceptThreads) [th cancel];
        if (udp6Broadcast >= 0) close(udp6Broadcast);
        if (udp4Broadcast >= 0) close(udp4Broadcast);
        if (server4Socket >= 0) close(server4Socket);
        if (server6Socket >= 0) close(server6Socket);
    }
    [super _handleError:error];
}

#pragma mark - Private -

- (void)startIPv4Acceptor {
    struct sockaddr_in serv_addr;
    server4Socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server4Socket < 0) return;
    
    bzero(&serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(self.port);
    
    int reuse = 1;
    setsockopt(server4Socket, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    
    if (bind(server4Socket, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        close(server4Socket);
        server4Socket = -1;
        return;
    }
    if (listen(server4Socket, 2) < 0) {
        close(server4Socket);
        server4Socket = -1;
        return;
    }
    
    NSThread * th = [[NSThread alloc] initWithTarget:self
                                            selector:@selector(acceptMethod:)
                                              object:@(server4Socket)];
    [acceptThreads addObject:th];
    [th start];
}

- (void)startIPv6Acceptor {
    struct sockaddr_in6 serv_addr6;
    struct in6_addr addr6 = IN6ADDR_ANY_INIT;
    server6Socket = socket(AF_INET6, SOCK_STREAM, 0);
    if (server6Socket < 0) return;
    
    bzero(&serv_addr6, sizeof(serv_addr6));
    serv_addr6.sin6_family = AF_INET6;
    serv_addr6.sin6_addr = addr6;
    serv_addr6.sin6_port = htons(self.port);
    
    int reuse = 1;
    setsockopt(server6Socket, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    
    if (bind(server6Socket, (struct sockaddr *)&serv_addr6, sizeof(serv_addr6)) < 0) {
        close(server6Socket);
        server6Socket = -1;
        return;
    }
    if (listen(server6Socket, 2) < 0) {
        close(server6Socket);
        server6Socket = -1;
        return;
    }
    
    NSThread * th = [[NSThread alloc] initWithTarget:self
                                            selector:@selector(acceptMethod:)
                                              object:@(server6Socket)];
    [acceptThreads addObject:th];
    [th start];
}

- (void)acceptMethod:(NSNumber *)fd {
    while (YES) {
        @autoreleasepool {
            int aConn = accept(fd.intValue, NULL, NULL);
            if ([[NSThread currentThread] isCancelled]) return;
            if (aConn < 0) {
                NSError * error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                                      code:errno
                                                  userInfo:nil];
                [self performSelectorOnMainThread:@selector(_handleError:)
                                       withObject:error
                                    waitUntilDone:NO];
                return;
            }
            ANTCPTransport * tp = [[ANTCPTransport alloc] initWithFileDescriptor:aConn];
            [self performSelectorOnMainThread:@selector(_handleClient:)
                                   withObject:tp
                                waitUntilDone:NO];
        }
    }
}

- (void)broadcastInformation {
    ANTCPTransportIdentity * identity = [ANTCPTransportIdentity localIdentity:self.port];
    NSData * payload = [identity encode];
    
    if (udp4Broadcast >= 0) {
        struct sockaddr_in s;
        bzero(&s, sizeof(struct sockaddr_in));
        s.sin_family = AF_INET;
        s.sin_port = (in_port_t)htons(self.bcastPort);
        s.sin_addr.s_addr = htonl(INADDR_BROADCAST);
        sendto(udp4Broadcast, payload.bytes, payload.length, 0, (struct sockaddr *)&s, sizeof(s));
    }
    if (udp6Broadcast >= 0) {
        struct sockaddr_in6 s6;
        struct in6_addr addr6 = IN6ADDR_ANY_INIT;
        bzero(&s6, sizeof(struct sockaddr_in6));
        s6.sin6_family = AF_INET6;
        s6.sin6_port = (in_port_t)htons(self.bcastPort);
        s6.sin6_addr = addr6;
        sendto(udp6Broadcast, payload.bytes, payload.length, 0, (struct sockaddr *)&s6, sizeof(s6));
    }
}

@end
