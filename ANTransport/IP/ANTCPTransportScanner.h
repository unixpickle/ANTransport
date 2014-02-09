//
//  ANTCPTransportScanner.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportScanner.h"
#import "ANTCPTransportIdentity.h"
#include <sys/socket.h>
#include <netinet/in.h>

#define kANTCPTransportScannerTimeout 10

@interface ANTCPTransportScanner : ANTransportScanner {
    UInt16 port;
    
    int fd4, fd6;
    NSThread * thread4, * thread6;
    
    NSMutableDictionary * lastSeens;
    NSTimer * timeoutLoop;
}

- (id)initWithPort:(UInt16)aPort;

@end
