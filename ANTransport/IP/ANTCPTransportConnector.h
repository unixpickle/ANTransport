//
//  ANTCPTransportConnector.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportConnector.h"
#import "ANTCPTransportIdentity.h"
#import "ANTCPTransport.h"
#include <netdb.h>

@interface ANTCPTransportConnector : NSObject <ANTransportConnector> {
    NSMutableArray * threads;
    BOOL open;
}

@property (nonatomic, copy) ANTransportConnectorBlock callback;
@property (nonatomic, strong) ANTCPTransportIdentity * identity;

@end
