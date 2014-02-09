//
//  ANTransportConnector.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransport.h"

typedef void (^ANTransportConnectorBlock)(NSError * error, id<ANTransport> transport);

@protocol ANTransportConnector <NSObject>

@property (nonatomic, copy) ANTransportConnectorBlock callback;

- (void)start;
- (void)cancel;

@end
