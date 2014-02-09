//
//  ANAppDelegate.h
//  TransportTester
//
//  Created by Alex Nichol on 2/8/14.
//  Copyright (c) 2014 Alex Nichol. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ANTCPTransportScanner.h"
#import "ANTCPTransportServer.h"

@interface ANAppDelegate : NSObject <NSApplicationDelegate, ANTransportScannerDelegate, ANTransportServerDelegate, NSTableViewDataSource> {
    ANTransportServer * server;
    ANTransportScanner * scanner;
    IBOutlet NSTableView * tableView;
}

@property (assign) IBOutlet NSWindow * window;

@end
