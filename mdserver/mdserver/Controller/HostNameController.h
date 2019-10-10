//
//  HostNameController.h
//  mdserver
//
//  Created by midoks on 15/2/2.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "NSTextField+MDTextField.h"

@interface HostNameController : NSDocument <NSTableViewDataSource, NSTableViewDelegate, NSPathControlDelegate, NSTextFieldDelegate>
{
    IBOutlet NSTableView *_tableView;
    IBOutlet NSPathControl *_serverPath;
    IBOutlet NSTextField *_serverName;
    IBOutlet NSTextField *_serverPort;
    IBOutlet NSPopUpButton *_serverPHPVer;
    
    
    IBOutlet NSTextField *_gPort;
    IBOutlet NSImageView *_emptyPath;
    
    NSMutableArray *_list;
    NSMutableArray *_phplist;
    
    IBOutlet NSTextField *pStartTitle;
    
    IBOutlet NSWindow *window;
}


- (IBAction)goWebSite:(id)sender;
- (IBAction)goWebInfo:(id)sender;

@end
