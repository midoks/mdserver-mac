//
//  GeneralController.m
//  mdserver
//
//  Created by midoks on 15/2/6.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import "GeneralController.h"
#import "NSCommon.h"

@implementation GeneralController

-(id)init
{
    //NSLog(@"GeneralController");
    if(self == [super init]){
    }
    return self;
}


-(void)awakeFromNib
{
    
    //初始化的数据
    NSString *str           = [NSCommon getRootDir];
    str = [NSString stringWithFormat:@"file://%@bin/nginx/logs/error.log", str];
    [_nginxLogPath setURL:[NSURL URLWithString:str]];
    
    NSString *httpPort = [NSCommon getCommonConfig:@"HttpPort"];
    NSString *mysqlPort = [NSCommon getCommonConfig:@"MysqlPort"];
    if (httpPort != nil) {
        [HttpPort setStringValue:httpPort];
    }else{
        [NSCommon setCommonConfig:@"HttpPort" value:[HttpPort stringValue]];
    }
   
    if (mysqlPort != nil) {
        [MysqlPort setStringValue:mysqlPort];
    }else{
        [NSCommon setCommonConfig:@"MysqlPort" value:[MysqlPort stringValue]];
    }
    
    NSString *s_SystemStartAfterStart = [NSCommon getCommonConfig:@"isSystemStartAfterStart"];
    if (s_SystemStartAfterStart == nil) {
        [NSCommon setCommonConfig:@"isSystemStartAfterStart" value:@"0"];
        [isSystemStartAfterStart setIntValue:0];
    }else{
        [isSystemStartAfterStart setIntValue:s_SystemStartAfterStart.intValue];
    }
    
    
    NSString *s_OpenAfterStart = [NSCommon getCommonConfig:@"isOpenAfterStart"];
    if (s_OpenAfterStart == nil) {
        [NSCommon setCommonConfig:@"isOpenAfterStart" value:@"0"];
        [isOpenAfterStart setIntValue:0];
    }else{
        [isOpenAfterStart setIntValue:s_OpenAfterStart.intValue];
    }
    
    NSString *s_ExitAfterCloseAll = [NSCommon getCommonConfig:@"isExitAfterCloseAll"];
    if (s_ExitAfterCloseAll == nil) {
        [NSCommon setCommonConfig:@"isExitAfterCloseAll" value:@"0"];
        [isExitAfterCloseAll setIntValue:0];
    }else{
        [isExitAfterCloseAll setIntValue:s_ExitAfterCloseAll.intValue];
    }
    
    NSString *s_StartAfterFlushLog = [NSCommon getCommonConfig:@"isStartAfterFlushLog"];
    if (s_StartAfterFlushLog == nil) {
        [NSCommon setCommonConfig:@"isStartAfterFlushLog" value:@"0"];
        [isStartAfterFlushLog setIntValue:0];
    }else{
        [isStartAfterFlushLog setIntValue:s_StartAfterFlushLog.intValue];
    }
}


-(IBAction)goNginxErrorLog:(id)sender
{
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:[_nginxLogPath URL], nil]] waitUntilExit];
}


-(void)setHttpPort:(NSString *)httpPort mysqlPort:(NSString *)mysqlPort
{
    [HttpPort setStringValue:httpPort];
    [MysqlPort setStringValue:mysqlPort];
    
    [NSCommon setCommonConfig:@"HttpPort" value:httpPort];
    [NSCommon setCommonConfig:@"MysqlPort" value:mysqlPort];
}


-(IBAction)setCommonPort:(id)sender
{
    NSString *httpPort = @"8000";
    NSString *mysqlPort = @"3306";
    [self setHttpPort:httpPort mysqlPort:mysqlPort];
}

-(IBAction)setSpecialPort:(id)sender
{
    NSString *httpPort = @"8888";
    NSString *mysqlPort = @"3307";
    [self setHttpPort:httpPort mysqlPort:mysqlPort];
}


#pragma mark 系统后启动本软件
-(IBAction)isSystemStartAfterStart:(id)sender
{
    NSString *i = [NSString stringWithFormat:@"%d", isSystemStartAfterStart.intValue];
    [NSCommon setCommonConfig:@"isSystemStartAfterStart" value:i];
}

#pragma mark 打开本软件时启动服务
-(IBAction)isOpenAfterStart:(id)sender
{
    NSString *i = [NSString stringWithFormat:@"%d", isOpenAfterStart.intValue];
    [NSCommon setCommonConfig:@"isOpenAfterStart" value:i];
}

#pragma mark 退出后停止所有程序
-(IBAction)isExitAfterCloseAll:(id)sender
{
    NSString *i = [NSString stringWithFormat:@"%d", isExitAfterCloseAll.intValue];
    [NSCommon setCommonConfig:@"isExitAfterCloseAll" value:i];
}

#pragma mark 启动后刷新日志
-(IBAction)isStartAfterFlushLog:(id)sender
{
    NSString *i = [NSString stringWithFormat:@"%d", isStartAfterFlushLog.intValue];
    [NSCommon setCommonConfig:@"isStartAfterFlushLog" value:i];
}
@end
