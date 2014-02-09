//
//  ANAppDelegate.m
//  TransportTester
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import "ANAppDelegate.h"

@implementation ANAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    tableView.dataSource = self;
    
    server = [[ANTCPTransportServer alloc] initWithPort:1224 broadcastPort:1223 flags:0];
    scanner = [[ANTCPTransportScanner alloc] initWithPort:1223];
    
    server.delegate = self;
    scanner.delegate = self;
    
    [server start];
    [scanner start];
}

#pragma mark - Scanner -

- (void)transportScanner:(id)transport failedWithError:(NSError *)error {
    NSRunAlertPanel(@"Scanner Error", @"Got scanner error: %@", @"OK", nil, nil, error.description);
}

- (void)transportScanner:(id)transport addIdentity:(id<ANTransportIdentity>)identity {
    [tableView reloadData];
}

- (void)transportScanner:(id)transport removeIdentity:(id<ANTransportIdentity>)identity {
    [tableView reloadData];
}

#pragma mark - Server -

- (void)transportServer:(id)sender gotTransport:(id<ANTransport>)transport {
    [transport close];
}

- (void)transportServer:(id)sender failedWithError:(NSError *)error {
    NSRunAlertPanel(@"Server Error", @"Got server error: %@", @"OK", nil, nil, error.description);
}

#pragma mark - Table View -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return scanner.identities.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id<ANTransportIdentity> ident = scanner.identities[row];
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        return [ident deviceName];
    } else if ([tableColumn.identifier isEqualToString:@"type"]) {
        return [ident deviceType];
    } else if ([tableColumn.identifier isEqualToString:@"flags"]) {
        return @([ident flags]);
    }
    return nil;
}

@end
