//
//  ANTCPTransport.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTCPTransport.h"

#define kTCPBufferSize 65535

@interface ANTCPTransport (Private)

- (void)readMethod;
- (void)writeMethod;
- (void)executeWrite:(NSData *)data;

- (void)handleClosed:(NSError *)posixCode;
- (void)handleData:(NSData *)data;

@end

@implementation ANTCPTransport

@synthesize open = _open;
@synthesize transportDelegate = _transportDelegate;

+ (void)initialize {
    signal(SIGPIPE, SIG_IGN);
}

- (id)initWithFileDescriptor:(int)_fd {
    if ((self = [super init])) {
        fd = _fd;
        readThread = [[NSThread alloc] initWithTarget:self selector:@selector(readMethod) object:nil];
        writeThread = [[NSThread alloc] initWithTarget:self selector:@selector(writeMethod) object:nil];
        [readThread start];
        [writeThread start];
        _open = YES;
    }
    return self;
}

- (void)close {
    if (self.isOpen) return;
    _open = NO;
    
    [readThread cancel];
    [writeThread cancel];
    close(fd);
}

- (void)writeData:(NSData *)data {
    [self performSelector:@selector(executeWrite:)
                 onThread:writeThread
               withObject:data
            waitUntilDone:NO
                    modes:@[NSRunLoopCommonModes]];
}

#pragma mark - Private -

- (void)readMethod {
    char buffer[kTCPBufferSize];
    
    while (YES) {
        @autoreleasepool {
            ssize_t result = read(fd, buffer, kTCPBufferSize);
            if ([[NSThread currentThread] isCancelled]) return;
            
            // do a read() loop here
            if (result < 0) {
                if (errno == EINTR) {
                    continue;
                }
                NSError * error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                                      code:errno
                                                  userInfo:nil];
                [self performSelectorOnMainThread:@selector(handleClosed:)
                                       withObject:error waitUntilDone:NO];
                return;
            }
            
            NSData * data = [[NSData alloc] initWithBytes:buffer length:result];
            [self performSelectorOnMainThread:@selector(handleData:)
                                   withObject:data waitUntilDone:NO];
        }
    }
}

- (void)writeMethod {
    @autoreleasepool {
        // TODO: make NSThread cancel work
        NSRunLoop * writeRunLoop = [NSRunLoop currentRunLoop];
        [writeRunLoop addPort:[[NSPort alloc] init] forMode:NSRunLoopCommonModes];
        [writeRunLoop run];
    }
}

- (void)executeWrite:(NSData *)data {
    const char * bytes = (const char *)data.bytes;
    size_t written = 0;
    while (written < data.length) {
        ssize_t result = write(fd, &bytes[written], data.length - written);
        if (result == 0) {
            // write queue is full
            [NSThread sleepForTimeInterval:0.001];
        } else if (result < 0) {
            if (errno == EINTR) continue;
            NSError * error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                                  code:errno
                                              userInfo:nil];
            [self performSelectorOnMainThread:@selector(handleClosed:) withObject:error waitUntilDone:NO];
            return;
        }
        written += result;
    }
}

- (void)handleClosed:(NSError *)posixCode {
    if (!self.isOpen) return;
    if ([self.transportDelegate respondsToSelector:@selector(transportClosed:withError:)]) {
        [self.transportDelegate transportClosed:self withError:posixCode];
    }
}

- (void)handleData:(NSData *)data {
    if (!self.isOpen) return;
    if ([self.transportDelegate respondsToSelector:@selector(transport:gotData:)]) {
        [self.transportDelegate transport:self gotData:data];
    }
}

@end
