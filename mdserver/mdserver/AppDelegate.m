//
//  AppDelegate.m
//  mdserver
//
//  Created by midoks on 15/1/22.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#include <mach-o/dyld.h>

@interface AppDelegate () <NSUserNotificationCenterDelegate>

@property IBOutlet NSWindow *window;
@property (nonatomic, strong) NSString *StartServerStatus;

@end

@implementation AppDelegate


#pragma mark - 公用方法 -
-(void)alert:(NSString *)content
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setInformativeText:content];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
}

#pragma mark 用户通知中心
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    //NSLog(@"通知已经递交！");
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //NSLog(@"用户点击了通知！");
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(void)userCenter:(NSString *)content
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    for (NSUserNotification *notify in [[NSUserNotificationCenter defaultUserNotificationCenter] scheduledNotifications])
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:notify];
    }
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"通知中心";
    notification.informativeText = content;
    
    //设置通知的代理
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

#pragma mark 延迟执行
- (void)delayedRun:(float)t callback:(void(^)()) callback
{
    double delayInSeconds = t;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        callback();
    });
}

#pragma mark 如果你希望调用系统命
- (void)runSystemCommand:(NSString *)cmd
{
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh"
                              arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]]
     waitUntilExit];
}

#pragma mark 打开文件
-(void)openFile:(NSString *)file
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:[NSArray arrayWithObject:file]];
    [task launch];
}

#pragma mark 获取cmd执行权限
-(void)AuthorizeCmd:(NSString *)cmdPath
{
    cmdPath = [NSString stringWithFormat:@"do shell script \"%@ > /tmp/me\" with administrator privileges", cmdPath];
    NSDictionary *error = [NSDictionary new];
    NSString *script = cmdPath;
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    if ([appleScript executeAndReturnError:&error]) {
        //NSLog(@"success!");
    } else {
        NSLog(@"failure!:%@", error);
    }
}

#pragma mark 获取cmd执行特权
#define ADMIN_PRIVILEGE     "system.privilege.admin"
//-(OSStatus)AcquireRight:(const char *)rightName
//// This routine calls Authorization Services to acquire
//// the specified right.
//{
//    OSStatus                         err;
//    static const AuthorizationFlags  kFlags =
//    kAuthorizationFlagInteractionAllowed
//    | kAuthorizationFlagExtendRights;
//    AuthorizationItem   kActionRight = { rightName, 0, 0, 0 };
//    AuthorizationRights kRights      = { 1, &kActionRight };
//    
//    assert(self->_authRef != NULL);
//    
//    // Request the application-specific right.
//    err = AuthorizationCopyRights(
//                                  self->_authRef,         // authorization
//                                  &kRights,               // rights
//                                  NULL,                   // environment
//                                  kFlags,                 // flags
//                                  NULL                    // authorizedRights
//                                  );
//    
//    return err;
//}
#pragma mark 给执行文件授权
-(void)AuthorizeCreate
{
    
    NSString *_str = [NSCommon getAppDir];
    NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", _str];
    NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", _str];
    NSString *ss = [NSString stringWithFormat:@"%@Contents/Resources/ss", _str];
    NSArray *list = [[NSArray alloc] initWithObjects:addhost, removehost, ss,nil];
    
    
    if (self->_authRef) {
        //NSLog(@"ok");
        return;
    }else{
        UInt32 count = (UInt32)[list count];
        AuthorizationItem authItem[count];
        AuthorizationRights authRights;
        AuthorizationFlags flags  = kAuthorizationFlagDefaults              |
                                    kAuthorizationFlagInteractionAllowed    |
                                    kAuthorizationFlagPreAuthorize          |
                                    kAuthorizationFlagExtendRights;
        
        authRights.count = (UInt32)count;
        //NSLog(@"count:%d", count);
        for (int i = 0;i<count; ++i ) {
            NSString *testFile = list[i];
            authItem[i].flags = 0;
            authItem[i].name = kAuthorizationRightExecute;
            authItem[i].valueLength = [testFile length];
            authItem[i].value = (void *)[testFile cStringUsingEncoding:NSASCIIStringEncoding];
            //NSLog(@"run: %d",i);
        }
        authRights.items = authItem;
        OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &self->_authRef);
        if(status != errAuthorizationSuccess){
            NSLog(@"AuthorizationCreate failed!");
            return;
        }else{
            NSLog(@"AuthorizationCreate ok!");
        }
    }
}

-(void)AuthorizeExeCmd:(NSString *)file
{
    //NSLog(@"file:%@", file);
    //虽然要被分离,但是我觉得最好用。
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored"-Wunused-variable"
    OSStatus  status_exe = AuthorizationExecuteWithPrivileges(self->_authRef, (void *)[file cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, nil, nil);
//#pragma clang diagnostic pop
    //NSLog(@"%d", status_exe);
    if (status_exe != errAuthorizationSuccess)
    {
        NSLog(@"AuthorizationExecuteWithPrivileges failed!:%d", status_exe);
        return;
    }
}

#pragma mark 获取进程
-(void)getProcess
{
    NSTask *task= [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/ps"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-ef", @"", @"grep php", nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog (@"got\n%@", string);
    NSLog(@"%@", task);
}


#pragma mark  - 小图标功能 -
- (IBAction)showAbout:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (IBAction)showMain:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:sender];
}

#pragma mark - 打开支付宝和微信的捐助窗口 -
- (IBAction)showDonateAlipay:(id)sender{
    NSWindowController *alipay =[[NSWindowController alloc] initWithWindowNibName:@"MainAlipay"];
    [alipay loadWindow];
    
    [alipay.window makeMainWindow];
    [NSApp activateIgnoringOtherApps:YES];
    [alipay.window makeKeyAndOrderFront:sender];
    [alipay.window orderFront:sender];
    [alipay.window center];
}


#pragma mark - 打开微博窗口 -
- (IBAction)showWeibo:(id)sender{
    NSWindowController *weibo =[[NSWindowController alloc] initWithWindowNibName:@"MainWeibo"];
    
    [weibo loadWindow];
    [weibo.window makeMainWindow];
    [weibo.window makeKeyAndOrderFront:sender];
    [weibo.window center];
}

#pragma mark - 打开nginx日志文件 -
- (IBAction)showNginxLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *nginx_access_log = [NSString stringWithFormat:@"%@/bin/nginx/logs/access.log", root];
    
    if ([NSCommon fileIsExists:nginx_access_log]) {
        [self openFile:nginx_access_log];
    }else{
        [NSCommon alert:@"Nginx日志暂时不存在"];
    }
}

#pragma mark - 打开php-fpm日志文件 -
- (IBAction)showPhpFpmLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *php_fpm_log = [NSString stringWithFormat:@"%@/bin/php/var/log/php-fpm.log", root];
    
    if ([NSCommon fileIsExists:php_fpm_log]){
        [self openFile:php_fpm_log];
    }else{
        [NSCommon alert:@"PHP-FPM日志暂时不存在"];
    }
}

#pragma mark - 打开mysql日志文件 -
- (IBAction)showMysqlLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *mysql_error_log = [NSString stringWithFormat:@"%@/bin/mysql/data/localhost.log", root];

    if ([NSCommon fileIsExists:mysql_error_log]){
        [self openFile:mysql_error_log];
    }else{
        [NSCommon alert:@"MySQL日志暂时不存在"];
    }
}


#pragma mark - 重新编译部分 -
- (IBAction)SelfCompilePHP:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"PHP编译"];
    [alert setInformativeText:@"你确定你要重新编译PHP程序"];
    [alert addButtonWithTitle:@"确定编译"];
    [alert addButtonWithTitle:@"取消编译"];
    NSModalResponse r = [alert runModal];

    if (r == 1000) {
         NSString *str = [NSCommon getRootDir];
        
        NSString *php_log = [NSString stringWithFormat:@"%@bin/logs/php.log", str];
        [self openFile:php_log];
        
       
        str = [NSString stringWithFormat:@"%@bin/reinstall/php.sh", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
        
        
    }
}

- (IBAction)SelfCompileNginx:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Nginx编译"];
    [alert setInformativeText:@"你确定你要重新编译Nginx程序"];
    [alert addButtonWithTitle:@"确定编译"];
    [alert addButtonWithTitle:@"取消编译"];
    NSModalResponse r = [alert runModal];
    
    if (r == 1000) {
        NSString *str = [NSCommon getRootDir];
        
        NSString *php_log = [NSString stringWithFormat:@"%@bin/logs/nginx.log", str];
        [NSCommon delayedRun:1.0 callback:^{
            [self openFile:php_log];
        }];
        
        str = [NSString stringWithFormat:@"%@bin/reinstall/nginx.sh", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
        //[self AuthorizeCmd:str];
    }
}

- (IBAction)SelfCompileMySQL:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"MySQL初始化"];
    [alert setInformativeText:@"你确定你要重新初始化MySQL程序"];
    [alert addButtonWithTitle:@"确定初始化"];
    [alert addButtonWithTitle:@"取消初始化"];
    NSModalResponse r = [alert runModal];
    
    if (r == 1000) {
        NSString *str = [NSCommon getRootDir];
        str = [NSString stringWithFormat:@"%@bin/reinstall/mysql.sh", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
        
        [NSCommon setCommonConfig:@"setMySQLPwd" value:@"root"];
    }
}

- (IBAction)SelfCompileYaf:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Yaf编译"];
    [alert setInformativeText:@"你确定你重新编译Yaf程序"];
    [alert addButtonWithTitle:@"确定编译"];
    [alert addButtonWithTitle:@"取消编译"];
    NSModalResponse r = [alert runModal];
    
    if (r == 1000) {
        NSString *str = [NSCommon getRootDir];
        NSString *yaf_log = [NSString stringWithFormat:@"%@bin/logs/yaf.log", str];
        [NSCommon delayedRun:1.0 callback:^{
            [self openFile:yaf_log];
        }];

        str = [NSString stringWithFormat:@"%@bin/reinstall/yaf.sh", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    }
}

#pragma mark - 运行调试Bash -
- (IBAction)SelfDebug:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"DEBUG测试"];
    [alert setInformativeText:@"你确定你重新执行DEBUG程序"];
    [alert addButtonWithTitle:@"确定编译"];
    [alert addButtonWithTitle:@"取消编译"];
    NSModalResponse r = [alert runModal];
    
    if (r == 1000) {
        NSString *str = [NSCommon getRootDir];
        
        NSString *debug_log = [NSString stringWithFormat:@"%@bin/logs/debug.log", str];
        [NSCommon delayedRun:1.0 callback:^{
            [self openFile:debug_log];
        }];
        
        str = [NSString stringWithFormat:@"%@bin/debug.sh", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    }
}

#pragma mark - 启动按钮 -
-(NSString *)stringReplace:(NSString *)c yes:(BOOL)yes
{
    NSString *str = [NSCommon getRootDir];
    if (yes == YES) {
        return [c stringByReplacingOccurrencesOfString:@"MD:/" withString:str];
    }else{
        return [c stringByReplacingOccurrencesOfString:str withString:@"MD:/"];
    }
}

-(void)replaceConfig:(NSString *)path yes:(BOOL)yes
{
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (yes == YES) {
        content = [self stringReplace:content yes:yes];
    }else{
        content = [self stringReplace:content yes:NO];
    }
    [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)replacePHP:(BOOL)yes
{
    NSString *str = [NSCommon getRootDir];
    NSString *php_ini = [NSString stringWithFormat:@"%@bin/php/etc/php.ini", str];
    [self replaceConfig:php_ini yes:yes];
}

-(void)replaceNginx:(BOOL)yes
{
    NSString *str           = [NSCommon getRootDir];
    NSString *nginx_conf    = [NSString stringWithFormat:@"%@bin/nginx/conf/nginx.conf", str];
    [self replaceConfig:nginx_conf yes:yes];
    
    //vhost下配置
    NSString *nginx_vhost = [NSString stringWithFormat:@"%@bin/nginx/conf/vhost", str];
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSArray *dirList = [fm contentsOfDirectoryAtPath:nginx_vhost error:nil];
    for (NSString *f in dirList) {
        if([f hasSuffix:@"conf"]){
            NSString *conf = [NSString stringWithFormat:@"%@/%@", nginx_vhost, f];
            [self replaceConfig:conf yes:yes];
        }
    }
}


//替换my.cnf
-(void)startCnfReplaceString
{
    NSString *str           = [NSCommon getRootDir];
    NSString *my_rcnf        = [NSString stringWithFormat:@"%@bin/tmp/my.cnf", str];

    NSString *my_cnf        = [[NSBundle mainBundle] pathForResource:@"my" ofType:@"cnf"];;
    NSString *my_content = [NSString stringWithContentsOfFile:my_cnf encoding:NSUTF8StringEncoding error:nil];
    
    //端口替换
    NSString *mysqlPort = [NSCommon getCommonConfig:@"MysqlPort"];
    if (!mysqlPort) {
        mysqlPort = @"3306";
    }
    my_content = [my_content stringByReplacingOccurrencesOfString:@"{SQL_PORT}"  withString:mysqlPort];
    [my_content writeToFile:my_rcnf atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

//启动配置文件替换
-(void)startConfReplaceString
{
    [self replacePHP:YES];//php.ini替换
    [self replaceNginx:YES];//nginx.conf替换
    [self startCnfReplaceString];
}

//停止配置文件替换
-(void)stopConfReplaceString
{
    [self replacePHP:NO];//php.ini替换
    [self replaceNginx:NO];//nginx.conf替换
}

- (void)startWebService
{
    NSString *_str  = [NSCommon getAppDir];
    NSString *str   = [NSCommon getRootDir];
    NSString *title = pStartTitle.stringValue;
    
    NSLog(@"start:开始启动");
    if ([title isEqual:@"start"]) {
        
        NSString *isflog = [NSCommon getCommonConfig:@"isStartAfterFlushLog"];
        if ([isflog isEqualTo:@"1"]) {
            [self startFlushLogContent];
        }
        
        NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", _str];
        [self AuthorizeExeCmd:addhost];
        
        [self startConfReplaceString];
        [NSCommon saveNginxConfig];
        
        //NSString *start = [NSString stringWithFormat:@"%@Contents/Resources/ss", _str];
        //sleep(2);
        //[self AuthorizeExeCmd:start];
        
        str = [NSString stringWithFormat:@"%@bin/start.sh", str];
        //[self AuthorizeCmd:str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    }
}

- (void)stopWebService
{
    NSLog(@"start:开始停止");
    NSString *str = [NSCommon getRootDir];
    NSString *_str = [NSCommon getAppDir];
    NSString *title = pStartTitle.stringValue;
    
    if([title isEqual:@"stop"]){
        //NSString *start = [NSString stringWithFormat:@"%@Contents/Resources/st", _str];
        //[self AuthorizeExeCmd:start];
        str = [NSString stringWithFormat:@"%@bin/stop.sh", str];
        //[self AuthorizeCmd:str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
        
        sleep(2);

        [self stopConfReplaceString];
        [NSCommon setRemoveAllConfig];
        NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", _str];
        [self AuthorizeExeCmd:removehost];
    }
}

#pragma mark 修改Host文件
- (void)modHostsFile
{
    
    NSString *content = [NSString stringWithContentsOfFile:@"/etc/hosts" encoding:NSUTF8StringEncoding error:nil];
    NSString *add = [NSCommon getHostFileNeedContent];
    content = [NSString stringWithFormat:@"%@\r\n%@", content, add];
    
    NSLog(@"c:%@", content);
    NSError *err;
    [content writeToFile:@"/etc/hosts" atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if(err != nil){
        NSLog(@"%@", err);
    }
}

#pragma mark 还原Host文件
-(void)removeHostFile
{
    NSString *content = [NSString stringWithContentsOfFile:@"/etc/hosts" encoding:NSUTF8StringEncoding error:nil];
    NSString *add = [NSCommon getHostFileNeedContent];
    content = [NSString stringWithFormat:@"%@\r\n%@", content, add];
    
    
    NSString *ok = [NSCommon setHostFileNotNeedContent:content];
    
    NSLog(@"----------------------------------------------------------------------------");
    NSLog(@"c:%@", ok);
    NSLog(@"----------------------------------------------------------------------------");
}


#pragma mark 启动时清空内容
-(void)startFlushLogContent
{
    NSString *root = [NSCommon getRootDir];
    
    NSString *nginx_error_log = [NSString stringWithFormat:@"%@/bin/nginx/logs/error.log", root];
    NSString *nginx_access_log = [NSString stringWithFormat:@"%@/bin/nginx/logs/access.log", root];
    NSString *mysql_error_log = [NSString stringWithFormat:@"%@/bin/mysql/data/localhost.log", root];
    NSString *php_fpm_log = [NSString stringWithFormat:@"%@/bin/php/var/log/php-fpm.log", root];
    
    [NSCommon setFlushLog:nginx_error_log];
    [NSCommon setFlushLog:nginx_access_log];
    [NSCommon setFlushLog:mysql_error_log];
    [NSCommon setFlushLog:php_fpm_log];
}

#pragma mark 打开本软件自动启动
-(void)selfStart
{
    if ([_StartServerStatus isEqual:@"starting"]) {
        [NSCommon alert:@"正在启动或停止中,勿再点击!!!"];
        return;
    }
    _StartServerStatus = @"starting";
    NSString *title = pStartTitle.stringValue;
    
    [pProgress setHidden:NO];
    [pProgress startAnimation:nil];

    if ([title isEqual:@"start"]) {
        [self startWebService];
    }else if([title isEqual:@"stop"]){
        [self stopWebService];
    }
    
    [self delayedRun:3.0f callback:^{
        _StartServerStatus = @"ended";
        [self checkWebStatus];
        [pProgress setHidden:YES];
        [pProgress stopAnimation:nil];
    }];
}

#pragma mark 按钮启动
- (IBAction)start:(id)sender {
    [self AuthorizeCreate];    
    [self selfStart];
}

#pragma mark 跳到开发地址
- (IBAction)goWeb:(id)sender {
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/"]];
    }else{
        [self alert:@"web服务未启动"];
    }
}

#pragma mark - 程序入口 -
#pragma mark 检查PHP-FPM是否启动
-(BOOL)checkWebPHP
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/php/var/run/php-fpm.pid", path];
    return [fm fileExistsAtPath:path];
}

#pragma mark 检查Nginx是否启动
-(BOOL)checkWebNginx
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/nginx/logs/nginx.pid", path];
    return [fm fileExistsAtPath:path];
}

#pragma mark 检查MySQL是否启动
-(BOOL)checkWebMySQL
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/mysql/data/localhost.pid", path];
    return [fm fileExistsAtPath:path];
}

#pragma mark 启动状态
-(void)checkWebStatus
{
    BOOL n = [self checkWebNginx];
    BOOL p = [self checkWebPHP];
    BOOL m = [self checkWebMySQL];
    
    if (n || p || m) {
        [self userCenter:@"启动成功"];
        [pStartTitle setStringValue:@"stop"];
        [pStart setImage:[NSImage imageNamed:@"stop"]];
        //NSLog(@"stoping");
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"started"];
    }else{
        [self userCenter:@"停止成功"];
        [pStartTitle setStringValue:@"start"];
        [pStart setImage:[NSImage imageNamed:@"start"]];
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"stoped"];
    }
    
    if (n) {
        pNginxStatus.state = 1;
    }else{
        pNginxStatus.state = 0;
    }
    
    if (p) {
        pPHPFPMStatus.state = 1;
    }else{
        pPHPFPMStatus.state = 0;
    }
    
    if (m) {
        pMySQLStatus.state = 1;
    }else{
        pMySQLStatus.state = 0;
    }
}


#pragma mark 设置界面UI
-(void)setBarStatus
{
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"mIcon"];
    statusBarItem.alternateImage = [NSImage imageNamed:@"mIcon"];
    statusBarItem.menu = statusBarItemMenu;
    statusBarItem.toolTip = @"mdserver is NOT Running";
    [statusBarItem setHighlightMode:YES];
}

-(void)setUI
{
    [self setBarStatus];
    
    //[_window setTitle:@"MDserver"];
    //[_window setTitlebarAppearsTransparent:NO];
    //[_windo];
    //[_window setMinSize:CGSizeMake(600, 500)];
    //[_window setMaxSize:CGSizeMake(600, 500)];
    //[_window makeMainWindow];
    //[_window addChildWindow:[[MainUIViewController alloc] init] ordered:NSWindowAbove];
}

#pragma mark 程序加载时执行
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSLog(@"%@", NSHomeDirectory());
    
    
    [self checkWebStatus];
    [self setUI];
    
    
    NSString *isos = [NSCommon getCommonConfig:@"isOpenAfterStart"];
    if ([isos isEqualTo:@"1"]) {
        sleep(1);
        [self startWebService];
    }
    
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
}

#pragma mark 程序退出时执行
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    NSString *iseall = [NSCommon getCommonConfig:@"isExitAfterCloseAll"];
    if ([iseall isEqualTo:@"1"]) {
        sleep(1);
        [self stopWebService];
    }
    
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
}
@end


