//
//  ANTCPTransportServer.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportServer.h"
#import "ANTCPTransport.h"
#import "ANTCPTransportIdentity.h"
#include <sys/socket.h>
#include <netinet/in.h>

#define kANTCPTransportServerHeartbeat 1

@interface ANTCPTransportServer : ANTransportServer {
    int udp4Broadcast, udp6Broadcast;
    int server4Socket, server6Socket;
    NSMutableArray * acceptThreads;
    NSTimer * broadcastTimer;
}

@property (readonly) UInt16 port;
@property (readonly) UInt16 bcastPort;

- (id)initWithPort:(UInt16)port broadcastPort:(UInt16)bcastPort flags:(UInt8)flags;

@end
