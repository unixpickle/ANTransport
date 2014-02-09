//
//  ANTransportConnector.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ANTransportConnector <NSObject>

- (void)start;
- (void)cancel;

@end
