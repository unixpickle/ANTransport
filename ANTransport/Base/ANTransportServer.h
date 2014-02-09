//
//  ANTransportServer.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransport.h"

@protocol ANTransportServerDelegate

@optional
- (void)transportServer:(id)sender gotTransport:(id<ANTransport>)transport;
- (void)transportServer:(id)sender failedWithError:(NSError *)error;

@end

@interface ANTransportServer : NSObject

@property (readonly) NSString * deviceName;
@property (readonly) NSString * deviceType;
@property (nonatomic, weak) id<ANTransportServerDelegate> delegate;
@property (readonly, getter = isOpen) BOOL open;
@property (readwrite) UInt8 flags;

- (id)initWithDeviceName:(NSString *)device type:(NSString *)type flags:(UInt8)flags;
- (BOOL)start;
- (void)stop;

- (void)_handleClient:(id<ANTransport>)transport;
- (void)_handleError:(NSError *)error;

@end
