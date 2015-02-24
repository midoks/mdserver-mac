//
//  GeneralController.h
//  mdserver
//
//  Created by midoks on 15/2/6.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface GeneralController : NSObject
{
    IBOutlet NSPathControl *_nginxLogPath;
    
    
    IBOutlet NSTextField *HttpPort;
    IBOutlet NSTextField *MysqlPort;
    
    
    //IBOutlet
    IBOutlet NSButton *isSystemStartAfterStart;
    IBOutlet NSButton *isOpenAfterStart;
    IBOutlet NSButton *isExitAfterCloseAll;
    IBOutlet NSButton *isStartAfterFlushLog;
}


#pragma mark 设置端口
-(IBAction)setCommonPort:(id)sender;
-(IBAction)setSpecialPort:(id)sender;

#pragma mark 系统后启动本软件
-(IBAction)isSystemStartAfterStart:(id)sender;
#pragma mark 打开本软件时启动服务
-(IBAction)isOpenAfterStart:(id)sender;
#pragma mark 退出后停止所有程序
-(IBAction)isExitAfterCloseAll:(id)sender;
#pragma mark 启动后刷新日志
-(IBAction)isStartAfterFlushLog:(id)sender;

@end
