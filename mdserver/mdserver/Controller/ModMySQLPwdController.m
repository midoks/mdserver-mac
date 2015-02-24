//
//  ModMySQLPwdController.m
//  mdserver
//
//  Created by midoks on 15/2/13.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import "ModMySQLPwdController.h"
#import "NSCommon.h"
#import <objc/objc.h>

@implementation ModMySQLPwdController


- (id)initWithWindow:(NSWindow *)window
{
    if (self = [super initWithWindow:window]) {

    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.window];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

-(void)windowWillClose:(NSNotification *)notification{
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
}

- (IBAction)exitMySQLPwd:(id)sender
{
    [self.window performClose:sender];
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
}

- (IBAction)updateMySQLPwd:(id)sender
{
    NSString *root = [NSCommon getRootDir];
    NSString *pwd = [mysqlPwd stringValue];
    NSString *repwd = [mysqlRePwd stringValue];
    
    NSString *WebServerStatus = [NSCommon getCommonConfig:@"WebServerStatus"];
    //NSLog(@"%@", WebServerStatus);
    if (WebServerStatus && [WebServerStatus isEqual:@"stoped"]) {
        [NSCommon alert:@"启动MySQL服务后才能修改!!!,Sorry"];
        return;
    }
    
    if ([pwd isNotEqualTo:repwd]) {
        [NSCommon alert:@"两次密码不一致!!!"];
        return;
    }
    
    if([pwd isEqual:@""]){
        [NSCommon alert:@"不能为空!!!"];
        return;
    }

    NSString *modMysqlSh            = [NSString stringWithFormat:@"%@bin/modMysqlPwd.sh", root];
    
    NSString *modMysqlPwd           = [[NSBundle mainBundle] pathForResource:@"modMysqlPwd" ofType:@"sh"];;
    NSString *modMysqlPwd_content   = [NSString stringWithContentsOfFile:modMysqlPwd encoding:NSUTF8StringEncoding error:nil];
    
    NSString *oldpassword = [NSCommon getCommonConfig:@"setMySQLPwd"];
    if (!oldpassword) {
        oldpassword = @"root";
    }
    
    modMysqlPwd_content = [modMysqlPwd_content stringByReplacingOccurrencesOfString:@"{OLD_PASSWORD}" withString:oldpassword];
    modMysqlPwd_content = [modMysqlPwd_content stringByReplacingOccurrencesOfString:@"{NEW_PASSWORD}" withString:pwd];
    [modMysqlPwd_content writeToFile:modMysqlSh atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c", modMysqlSh, nil]];
    [task launch];
    [task waitUntilExit];
    
    if(task.terminationStatus!=0){
        [NSCommon alert:@"修改失败!!!"];
        return;
    }
    
    
    [self.window performClose:sender];
    [NSCommon setCommonConfig:@"setMySQLPwd" value:pwd];
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
    
    NSString *empty= @"#Don`t Delele This File;";
    [empty writeToFile:modMysqlSh
            atomically:YES
              encoding:NSUTF8StringEncoding error:nil];
    
    [NSCommon alert:@"修改成功!!!"];
}


@end
