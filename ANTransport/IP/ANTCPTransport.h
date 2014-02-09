//
//  ANTCPTransport.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransport.h"

@interface ANTCPTransport : NSObject <ANTransport> {
    int fd;
    NSThread * readThread, * writeThread;
}

@property (nonatomic, weak) id<ANTransportDelegate> transportDelegate;
@property (readonly, getter = isOpen) BOOL open;

+ (void)initialize;
- (id)initWithFileDescriptor:(int)fd;

@end
