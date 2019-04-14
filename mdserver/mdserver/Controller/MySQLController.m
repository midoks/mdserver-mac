//
//  MySQLController.m
//  mdserver
//
//  Created by midoks on 15/2/8.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import "MySQLController.h"
#import "NSCommon.h"
#import "ModMySQLPwdController.h"

@interface MySQLController()
{
    ModMySQLPwdController *myp;
}
@end

@implementation MySQLController

-(id)init
{
    if (self = [super init]) {
        
    }
    return self;
}


-(void)awakeFromNib
{
//    NSLog(@"MySQLController");
    
    NSString *str           = [NSCommon getRootDir];
    str = [NSString stringWithFormat:@"file://%@bin/mysql/data/localhost.log", str];
    [_mysqlLogPath setURL:[NSURL URLWithString:str]];
    
    
    if (isAllowToLinkMysql.intValue == 0) {
        AllowConnectType.enabled = NO;
        [NSCommon setCommonConfig:@"isAllowToConnectMysql" value:@"0"];
    }else{
        AllowConnectType.enabled = YES;
        [NSCommon setCommonConfig:@"isAllowToConnectMysql" value:@"1"];
    }
    
    if (AllowConnectLocalMysql.intValue == 1) {
        [NSCommon setCommonConfig:@"AllowConnectLocalMysql" value:@"1"];
        [NSCommon setCommonConfig:@"AllowConnectOtherMysql" value:@"0"];
    }else{
        [NSCommon setCommonConfig:@"AllowConnectLocalMysql" value:@"0"];
        [NSCommon setCommonConfig:@"AllowConnectOtherMysql" value:@"1"];
    }
}

-(IBAction)isAllowToConnectMysql:(id)sender
{
    if (isAllowToLinkMysql.intValue == 0) {
        AllowConnectType.enabled = NO;
        [NSCommon setCommonConfig:@"isAllowToConnectMysql" value:@"0"];
    }else{
        AllowConnectType.enabled = YES;
        [NSCommon setCommonConfig:@"isAllowToConnectMysql" value:@"1"];
    }
}

- (IBAction)AllowConnectLocalMysql:(id)sender {
    [NSCommon setCommonConfig:@"AllowConnectLocalMysql" value:@"1"];
    [NSCommon setCommonConfig:@"AllowConnectOtherMysql" value:@"0"];
}

- (IBAction)AllowConnectOtherMysql:(id)sender {
    //NSLog(@"AllowConnectLocalMysql:%d", AllowConnectLocalMysql.isHighlighted);
    [NSCommon setCommonConfig:@"AllowConnectLocalMysql" value:@"0"];
    [NSCommon setCommonConfig:@"AllowConnectOtherMysql" value:@"1"];
}

#pragma mark 跳到mysql日志
-(IBAction)goMysqlLogPath:(id)sender
{
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:[_mysqlLogPath URL], nil]] waitUntilExit];
}

#pragma mark - 辅助工具 -
-(IBAction)goPhpMysqAdmin:(id)sender
{
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/phpMyAdmin"]];
    }else{
        [NSCommon alert:@"web服务未启动"];
    }
}

-(IBAction)goSequelPro:(id)sender
{
    NSString *str           = [NSCommon getRootDir];
    str = [NSString stringWithFormat:@"file://%@bin/Sequel Pro.app", str];
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];

}



#pragma mark - MySQL密码修改 -
- (IBAction)modMySQLPwd:(id)sender
{
    NSString *status = [NSCommon getCommonConfig:@"isOpenModMySQLPwdWindow"];
    if(status)
    {
        if ([status isNotEqualTo:@"yes"]) {
            myp = [[ModMySQLPwdController alloc] initWithWindowNibName:@"ModMySQLPwd"];
            [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"yes"];
        }
    }else{
        myp = [[ModMySQLPwdController alloc] initWithWindowNibName:@"ModMySQLPwd"];
        [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"yes"];
    
    }
    
    [myp loadWindow];
    [myp.window makeMainWindow];
    [myp.window makeKeyAndOrderFront:sender];
    [myp.window center];
    
//    NSLog(@"b:%@", myp);
//    [NSApp beginSheet:[myp window]
//       modalForWindow:[NSApp mainWindow]
//        modalDelegate:self
//       didEndSelector:nil
//          contextInfo:nil];
//    [myp.window center];
//    NSLog(@"e:%@", myp);
    
    
//    [NSApp beginSheet:[myp window] completionHandler:^(NSModalResponse returnCode) {
//        NSLog(@"%ld", returnCode);
//    }];
}

@end
