//
//  ANTransportScanner.m
//  ANTransport
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANTransportScanner.h"

@implementation ANTransportScanner

- (id)init {
    if ((self = [super init])) {
        _identities = [NSMutableArray array];
    }
    return self;
}

- (BOOL)start {
    if (self.open) return NO;
    return _open = YES;
}

- (void)stop {
    _open = NO;
}

- (NSArray *)identities {
    return [_identities copy];
}

- (void)_handleFailed:(NSError *)error {
    if (!self.open) return;
    _open = NO;
    if ([self.delegate respondsToSelector:@selector(transportScanner:failedWithError:)]) {
        [self.delegate transportScanner:self failedWithError:error];
    }
}

- (void)_handleIdentity:(id<ANTransportIdentity>)identity {
    if (!self.open) return;
    if ([self.identities containsObject:identity]) return;
    [_identities addObject:identity];
    if ([self.delegate respondsToSelector:@selector(transportScanner:addIdentity:)]) {
        [self.delegate transportScanner:self addIdentity:identity];
    }
}

- (void)_handleIdentityGone:(id<ANTransportIdentity>)identity {
    if (!self.open) return;
    if (![_identities containsObject:identity]) return;
    [_identities removeObject:identity];
    if ([self.delegate respondsToSelector:@selector(transportScanner:removeIdentity:)]) {
        [self.delegate transportScanner:self removeIdentity:identity];
    }
}

@end
