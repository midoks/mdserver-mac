//
//  MySQLController.h
//  mdserver
//
//  Created by midoks on 15/2/8.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface MySQLController : NSWindowController
{
    IBOutlet NSPathControl *_mysqlLogPath;
    
    IBOutlet NSButton *isAllowToLinkMysql;
    IBOutlet NSMatrix *AllowConnectType;
    IBOutlet NSButtonCell *AllowConnectLocalMysql;
    IBOutlet NSButtonCell *AllowConnectOtherMysql;
    
    
    IBOutlet NSTextField *pStartTitle;
}


#pragma mark 是否允许链接Mysql
-(IBAction)isAllowToConnectMysql:(id)sender;
- (IBAction)AllowConnectLocalMysql:(id)sender;
- (IBAction)AllowConnectOtherMysql:(id)sender;


#pragma mark - 辅助工具 -
-(IBAction)goPhpMysqAdmin:(id)sender;
-(IBAction)goSequelPro:(id)sender;


#pragma mark - 更改mysql密码 -
- (IBAction)modMySQLPwd:(id)sender;


@end
