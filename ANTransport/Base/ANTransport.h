//
//  ANTransport.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ANTransportDelegate <NSObject>

@optional
- (void)transport:(id)tp gotData:(NSData *)data;
- (void)transportClosed:(id)tp withError:(NSError *)err;

@end

@protocol ANTransport <NSObject>

@property (nonatomic, weak) id<ANTransportDelegate> transportDelegate;
@property (readonly, getter = isOpen) BOOL isOpen;

- (void)close;
- (void)writeData:(NSData *)data;

@end
