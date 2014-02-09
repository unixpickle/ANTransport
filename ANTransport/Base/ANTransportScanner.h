//
//  ANTransportScanner.h
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportIdentity.h"

@protocol ANTransportScannerDelegate <NSObject>

@optional
- (void)transportScanner:(id)transport failedWithError:(NSError *)error;
- (void)transportScanner:(id)transport addIdentity:(id<ANTransportIdentity>)identity;
- (void)transportScanner:(id)transport removeIdentity:(id<ANTransportIdentity>)identity;

@end

@interface ANTransportScanner : NSObject {
    NSMutableArray * _identities;
}

@property (nonatomic, weak) id<ANTransportScannerDelegate> delegate;
@property (readonly, getter = isOpen) BOOL open;

- (BOOL)start;
- (void)stop;
- (NSArray *)identities;

- (void)_handleFailed:(NSError *)error;
- (void)_handleIdentity:(id<ANTransportIdentity>)identity;
- (void)_handleIdentityGone:(id<ANTransportIdentity>)identity;


@end
