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

#define PHP_C_VER_KEY @"php_version"
#define PHP_S_VER_KEY @"php_S_version"
#define MYSQL_C_VER_KEY @"mysql_version"

#define kMDHelper @"/Library/Application Support/mdserver/addhost"

@interface AppDelegate () <NSUserNotificationCenterDelegate>

@property IBOutlet NSWindow *window;
@property (nonatomic, strong) NSString *StartServerStatus;

@property (nonatomic, strong) IBOutlet NSButton *mMongoTool;
@property (nonatomic, strong) IBOutlet NSButton *mRedisTool;
@property (nonatomic, strong) IBOutlet NSButton *mMemcachedTool;
@property (nonatomic, strong) IBOutlet NSButton *mMySQLTool;

@property (nonatomic, strong) IBOutlet NSButton *mMongoButton;
@property (nonatomic, strong) IBOutlet NSButton *mRedisButton;
@property (nonatomic, strong) IBOutlet NSButton *mMemcachedButton;
@property (nonatomic, strong) IBOutlet NSButton *mMySQLButton;

//@property (nonatomic, strong) IBOutlet NSSubmenuWindowLevel *phpSwitch;

@end

@implementation AppDelegate


#pragma mark - 公用方法 -
-(void)alert:(NSString *)content
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setInformativeText:content];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
}

#pragma mark 用户通知中心
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
- (void)delayedRun:(float)t callback:(void(^)(void)) callback
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
#pragma mark 给执行文件授权
-(BOOL)AuthorizeCreate
{
    NSString *app_dir = [NSCommon getAppDir];
//    NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", app_dir];
//    NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", app_dir];
    NSString *ss = [NSString stringWithFormat:@"%@Contents/Resources/ss", app_dir];
    NSString *root_dir = [NSCommon getRootDir];
    
    NSString *startNginx = [NSString stringWithFormat:@"%@bin/startNginx.sh", root_dir];
    NSString *stopNginx = [NSString stringWithFormat:@"%@bin/stopNginx.sh", root_dir];
    NSString *redis = [NSString stringWithFormat:@"%@bin/redis.sh", root_dir];
    NSArray *list = [[NSArray alloc] initWithObjects:
//采用新的授权方式
//                     addhost, removehost,
                     ss, startNginx,stopNginx,redis, nil];
    
    if (self->_authRef) {
        //NSLog(@"ok");
        return true;
    }else{
        UInt32 count = (UInt32)[list count];
        AuthorizationItem authItem[count];
        AuthorizationRights authRights;
        AuthorizationFlags flags  = kAuthorizationFlagDefaults|
        kAuthorizationFlagInteractionAllowed |
        kAuthorizationFlagPreAuthorize |
        kAuthorizationFlagExtendRights |
        kAuthorizationFlagPartialRights |
        kAuthorizationFlagPreAuthorize;
        
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
        }else{
            NSLog(@"AuthorizationCreate ok!");
            return true;
        }
    }
    
    [self userCenter:@"授权失败!"];
    return false;
}



//虽然要被分离,但是我觉得最好用。
-(void)AuthorizeExeCmd:(NSString *)file
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    char *args[] = {NULL};
    OSStatus  status_exe = AuthorizationExecuteWithPrivileges(self->_authRef, (void *)[file cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, args, nil);
    if (status_exe != 0)//errAuthorizationSuccess
    {
        NSLog(@"AuthorizationExecuteWithPrivileges failed!:%d:%@", status_exe,file);
        return;
    }
#pragma clang diagnostic pop
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

#pragma mark  - 显示界面 -
- (IBAction)showMain:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:sender];
}

- (IBAction)showDonateAlipay:(id)sender{
    NSWindowController *alipay =[[NSWindowController alloc] initWithWindowNibName:@"MainAlipay"];
    [alipay loadWindow];
    
    [alipay.window makeMainWindow];
    [NSApp activateIgnoringOtherApps:YES];
    [alipay.window makeKeyAndOrderFront:sender];
    [alipay.window orderFront:sender];
    [alipay.window center];
}

- (IBAction)showWeibo:(id)sender{
    NSWindowController *weibo =[[NSWindowController alloc] initWithWindowNibName:@"MainWeibo"];
    
    [weibo loadWindow];
    [weibo.window makeMainWindow];
    [weibo.window makeKeyAndOrderFront:sender];
    [weibo.window center];
}

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
    NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
    
    NSString *rootDir = [NSCommon getRootDir];
    NSString *php_ini = [NSString stringWithFormat:@"%@bin/php/%@/etc/php.ini", rootDir, php_version];
    [self replaceConfig:php_ini yes:yes];
    
    NSString *php_fpm = [NSString stringWithFormat:@"%@bin/php/%@/etc/php-fpm.conf", rootDir, php_version];
    [self replaceConfig:php_fpm yes:yes];
}

-(void)replaceOpenresty:(BOOL)yes
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *nginx_conf    = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/nginx.conf", rootDir];
    [self replaceConfig:nginx_conf yes:yes];
    
    NSString *nginx_conf_tpl    = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/nginx.tpl.conf", rootDir];
    [self replaceConfig:nginx_conf_tpl yes:yes];
    
    //vhost下配置
    NSString *resty_vhost = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/vhost", rootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSArray *dirList = [fm contentsOfDirectoryAtPath:resty_vhost error:nil];
    for (NSString *f in dirList) {
        if([f hasSuffix:@"conf"]){
            NSString *conf = [NSString stringWithFormat:@"%@/%@", resty_vhost, f];
            [self replaceConfig:conf yes:yes];
        }
    }
}


//替换my.cnf
-(void)startCnfReplaceString
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *str            = [NSCommon getRootDir];
    NSString *my_rcnf        = [NSString stringWithFormat:@"%@bin/tmp/my.cnf", str];
    
    NSString *my_content = @"";
    if ([fm fileExistsAtPath:my_rcnf]){
        my_content = [NSString stringWithContentsOfFile:my_rcnf encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSString *my_cnf        = [[NSBundle mainBundle] pathForResource:@"my" ofType:@"cnf"];
        my_content = [NSString stringWithContentsOfFile:my_cnf encoding:NSUTF8StringEncoding error:nil];
    }
    
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
    [self replaceOpenresty:YES];//openresty替换
    [self startCnfReplaceString];
    
    [NSCommon saveNginxConfig];
}

//停止配置文件替换
-(void)stopConfReplaceString
{
    [self replacePHP:NO];//php.ini替换
    [self replaceOpenresty:NO];//openresty替换
    
    [NSCommon setRemoveAllConfig];
}


#pragma mark - 启动服务 -
- (void)startWebService
{
//    NSString *appDir  = [NSCommon getAppDir];
    NSString *rootDir   = [NSCommon getRootDir];
    NSString *supportDir = [NSCommon getSupportDir];
    NSString *title = pStartTitle.stringValue;
    
    if ([title isEqual:@"start"]) {
        
        [NSCommon delayedRun:0 callback:^{
            NSString *isflog = [NSCommon getCommonConfig:@"isStartAfterFlushLog"];
            if ([isflog isEqualTo:@"1"]) {
                [self startFlushLogContent];
            }
            
            NSString *addhost = [NSString stringWithFormat:@"cd %@ && ./addhost", supportDir];
//采用新的授权的方式
//          [self AuthorizeExeCmd:addhost];
            
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", addhost, nil]] waitUntilExit];
            [self startConfReplaceString];
            sleep(0.1);
            
            NSString *nginx = [NSString stringWithFormat:@"cd %@ && ./script.sh start", supportDir];
//            [self AuthorizeExeCmd:nginx];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", nginx, nil]] waitUntilExit];
            
            NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
            NSString *php = [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, php_version];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", php, nil]] waitUntilExit];
            
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, [NSCommon getCommonConfig:PHP_S_VER_KEY]], nil]] waitUntilExit];
            
            
            NSArray* list = [NSCommon getAllPhpVer];
            for (NSString* php_ver in list) {
                if ([php_ver isEqualTo:[NSCommon getCommonConfig:PHP_C_VER_KEY]]
                    || [php_ver isEqualTo:[NSCommon getCommonConfig:PHP_S_VER_KEY]] ){
                }else{
                    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, php_ver], nil]] waitUntilExit];
                }
            }
            [self userCenter:@"启动成功"];
        }];

    }
}

#pragma mark - 停止服务 -
- (void)stopWebService
{
    NSString *rootDir = [NSCommon getRootDir];
//    NSString *appDir = [NSCommon getAppDir];
    NSString *supportDir = [NSCommon getSupportDir];
    NSString *title = pStartTitle.stringValue;
    
    if([title isEqual:@"stop"]){
        
        [NSCommon delayedRun:0 callback:^{
            
            NSString *nginx = [NSString stringWithFormat:@"cd %@ && ./script.sh stop", supportDir];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", nginx, nil]] waitUntilExit];
//            [self AuthorizeExeCmd:nginx];
            
            NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
            NSString *php = [NSString stringWithFormat:@"%@bin/php/status.sh %@ stop", rootDir, php_version];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", php, nil]] waitUntilExit];
            
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@bin/php/status.sh %@ stop", rootDir, [NSCommon getCommonConfig:PHP_S_VER_KEY]], nil]] waitUntilExit];
            
            NSString *removehost = [NSString stringWithFormat:@"cd %@ && ./removehost", supportDir];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", removehost, nil]] waitUntilExit];
//采用新的授权的方式
//            [self AuthorizeExeCmd:removehost];
            
            [self stopConfReplaceString];
            [self userCenter:@"停止成功"];
        }];
    
    }
}

#pragma mark - 重置服务 -
//-(IBAction)reloadSVC:(id)sender
//{
//    if ([self AuthorizeCreate]){
//        NSString *rootDir = [NSCommon getRootDir];
//        NSString *reloadSVC = [NSString stringWithFormat:@"%@bin/reloadSVC.sh", rootDir];
//        [self AuthorizeExeCmd:reloadSVC];
//    }
//}

#pragma mark 启动时清空内容
-(void)startFlushLogContent
{
    NSString *rootDir = [NSCommon getRootDir];
    rootDir = [NSString stringWithFormat:@"%@bin/flush.sh", rootDir];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rootDir, nil]] waitUntilExit];
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
        self->_StartServerStatus = @"ended";
        [self checkWebStatus];
        [self->pProgress setHidden:YES];
        [self->pProgress stopAnimation:nil];
    }];
}

#pragma mark - 一次性授权方式 -
- (void)installHelp {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:kMDHelper]) {
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"/bin/bash \\\"%@\\\"\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"installation success");
        } else {
            NSLog(@"installation failure: %@", error);
        }
    }
}

#pragma mark - 按钮启动 -
- (IBAction)start:(id)sender {
//    if ([self AuthorizeCreate]){
    [self selfStart];
//    }
}

#pragma mark - 重新启动 -
-(void)selfReStart
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
        
        _StartServerStatus = @"ended";
        [pProgress setHidden:YES];
        [pProgress stopAnimation:nil];
        [self checkWebStatus];
        [self alert:@"启动后,才能重启!!!"];
        
    }else if([title isEqual:@"stop"]){
        
        NSString *supportDir = [NSCommon getSupportDir];
        
        NSString *removehost = [NSString stringWithFormat:@"cd %@ && ./removehost", supportDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", removehost, nil]] waitUntilExit];
        NSString *addhost = [NSString stringWithFormat:@"cd %@ && ./addhost", supportDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", addhost, nil]] waitUntilExit];
        
        [self stopConfReplaceString];
        [self startConfReplaceString];
        
        //NSLog(@"rootDir:%@",rootDir);
        NSString *reload = [NSString stringWithFormat:@"cd %@ && ./script.sh reload", supportDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", reload, nil]] waitUntilExit];
    }
    
    [self delayedRun:1.0f callback:^{
        self->_StartServerStatus = @"ended";
        [self checkWebStatus];
        [self->pProgress setHidden:YES];
        [self->pProgress stopAnimation:nil];
    }];
}

#pragma mark - 重启启动 -
- (IBAction)reStart:(id)sender {
    [self selfReStart];
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

#pragma mark - redis和mongodb相关功能 && Memcached && MySQL -

-(IBAction)goRedisWeb:(id)sender
{
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/phpRedisAdmin/"]];
    }else{
        [self alert:@"web服务未启动"];
    }
    
}

-(IBAction)goMongoWeb:(id)sender
{
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/rockmongo/"]];
    }else{
        [self alert:@"web服务未启动"];
    }
    
}

-(IBAction)goMemcached:(id)sender
{
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/memadmin/"]];
    }else{
        [self alert:@"web服务未启动"];
    }
}

-(IBAction)goMySQL:(id)sender
{
    NSString *title = [pStartTitle stringValue];
    if ([title isEqual:@"stop"]) {
        
        NSString *phpVer = [NSCommon getCommonConfig:@"selectPhpVer"];
        
        if ([phpVer intValue]>70){
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/phpMyAdmin7/"]];
        }  else {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/phpMyAdmin/"]];
        }
        
    }else{
        [self alert:@"web服务未启动"];
    }
}

#pragma mark - goNeo4j -
//- (IBAction)goNeo4j:(id)sender {
//    NSString *str           = [NSCommon getRootDir];
//    str = [NSString stringWithFormat:@"file://%@bin/Neo4j.app", str];
//    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];
//}

-(IBAction)redisStart:(id)sender
{
    NSString *str   = [NSCommon getRootDir];
    //NSLog(@"%@",str);
    //str = @"/Applications/mdserver/";
    if( _mRedisButton.state == 1 ){
        str = [NSString stringWithFormat:@"%@bin/redis.sh start", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    } else {
        str = [NSString stringWithFormat:@"%@bin/redis.sh stop", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    }
    [self checkRedisStatus];
}


-(IBAction)mongoStart:(id)sender
{
    NSString *rootDir   = [NSCommon getRootDir];
    if( _mMongoButton.state == 1 ){
        rootDir = [NSString stringWithFormat:@"%@bin/mongodb.sh start", rootDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rootDir, nil]] waitUntilExit];
    } else {
        rootDir = [NSString stringWithFormat:@"%@bin/mongodb.sh stop", rootDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rootDir, nil]] waitUntilExit];
    }
    [self checkMongoStatus];
}

-(IBAction)memcachedStart:(id)sender
{
    NSString *str   = [NSCommon getRootDir];
    if( _mMemcachedButton.state == 1 ){
        str = [NSString stringWithFormat:@"%@bin/memcached.sh start", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    } else {
        str = [NSString stringWithFormat:@"%@bin/memcached.sh stop", str];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", str, nil]] waitUntilExit];
    }
    [self checkMemcachedStatus];
    
}

-(IBAction)MySQLStart:(id)sender
{
//    NSString *rootDir   = [NSCommon getRootDir];
//    if (_mMySQLButton.state == 1) {
//        NSString *mysql = [NSString stringWithFormat:@"%@bin/mysql/mysql80/start.sh", rootDir];
//        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", mysql, nil]] waitUntilExit];
//    } else {
//        NSString *mysql = [NSString stringWithFormat:@"%@bin/mysql/mysql80/stop.sh", rootDir];
//        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", mysql, nil]] waitUntilExit];
//    }
    
    NSString *myVer = [NSCommon getCommonConfig:MYSQL_C_VER_KEY];
    [self mysqlTrigger:myVer];
    sleep(3);

    
    [self checkMySQLOnStatus];
}

-(BOOL)checkRedisStatus
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/redis/data/redis.pid", path];
    BOOL isStart = [fm fileExistsAtPath:path];
    
    if(isStart){
        _mRedisTool.enabled = TRUE;
        _mRedisButton.state = 1;
    } else {
        _mRedisTool.enabled = FALSE;
        _mRedisButton.state = 0;
    }
    return isStart;
}

-(BOOL)checkMongoStatus
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/mongodb/logs/mongodb.pid", path];
    BOOL isStart = [fm fileExistsAtPath:path];
    
    if(isStart){
        _mMongoTool.enabled = TRUE;
        _mMongoButton.state = 1;
    } else {
        _mMongoTool.enabled = FALSE;
        _mMongoButton.state = 0;
    }
    return isStart;
}

-(BOOL)checkMemcachedStatus
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/memcached/mem.pid", path];
    BOOL isStart = [fm fileExistsAtPath:path];
    
    //NSLog(@"isStart:%hhd", isStart);
    if(isStart){
        _mMemcachedTool.enabled = TRUE;
        _mMemcachedButton.state = 1;
    } else {
        _mMemcachedTool.enabled = FALSE;
        _mMemcachedButton.state = 0;
    }
    return isStart;
}

#pragma mark 检查MySQL是否启动
-(BOOL)checkMySQLOnStatus
{
    NSString *myVer = [NSCommon getCommonConfig:MYSQL_C_VER_KEY];
    BOOL isStart =[self checkMysqlStatus:myVer];

    if (isStart){
        _mMySQLTool.enabled = TRUE;
        _mMySQLButton.state = 1;
    } else {
        _mMySQLTool.enabled = FALSE;
        _mMySQLButton.state = 0;
    }
 
    return isStart;
}

#pragma mark - 程序入口 -

#pragma mark 检查PHP-FPM是否启动
-(BOOL)checkWebPHP:(NSString *)ver
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [NSString stringWithFormat:@"/tmp/php%@-cgi.sock", ver];
    return [fm fileExistsAtPath:path];
}

-(BOOL) rmPHPSockFile:(NSString *)ver
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [NSString stringWithFormat:@"/tmp/php%@-cgi.sock", ver];
    if ([fm fileExistsAtPath:path]){
        return [fm removeItemAtPath:path error:nil];
    }
    return NO;
}

#pragma mark 检查Nginx是否启动
-(BOOL)checkWebNginx
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/tmp/nginx.pid", path];
    return [fm fileExistsAtPath:path];
}

#pragma mark 启动状态
-(void)checkWebStatus
{
    BOOL n = [self checkWebNginx];
    
    if (n) {
        [pStartTitle setStringValue:@"stop"];
        [pStart setImage:[NSImage imageNamed:@"stop"]];
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"started"];
    }else{
        [pStartTitle setStringValue:@"start"];
        [pStart setImage:[NSImage imageNamed:@"start"]];
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"stoped"];
    }
    
    if (n) {
        pNginxStatus.state = 1;
        
        NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
        BOOL p = [self checkWebPHP:php_version];
        if (p) {
            pPHPStatus.state = 1;
        }else{
            pPHPStatus.state = 0;
        }
        
    }else{
        pPHPStatus.state = 0;
        pNginxStatus.state = 0;
    }
}

#pragma mark 检查CMD是否启动进程
-(BOOL)checkCmdStatus:(NSString *)name
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmdFile = [NSString stringWithFormat:@"%@bin/tmp/cmd/%@.lock", rootDir, name];
    return [fm fileExistsAtPath:cmdFile];
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

#pragma mark - 初始化CMD列表 -
-(NSMenu*)getCmdMenu:(NSString *)title
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    
    
    [menu addItemWithTitle:@"Install" action:@selector(cmdInstall:) keyEquivalent:@""];
    [menu addItemWithTitle:@"UnInstall" action:@selector(cmdUninstall:) keyEquivalent:@""];
    
    
    NSString *reloadSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/reload.sh", rootDir, title];
    BOOL isDir = YES;
    if([fm fileExistsAtPath:reloadSh isDirectory:&isDir]){
        [menu addItemWithTitle:@"Reload" action:@selector(cmdReload:) keyEquivalent:@""];
    }
    
    [menu addItemWithTitle:@"Dir" action:@selector(cmdDir:) keyEquivalent:@""];
    return menu;
}

#pragma mark - 递归生产菜单 -
-(BOOL)checkMenuDir:(NSString *)name transmit:(NSString *)transmit path:(NSString *)path menu:(NSMenu *)menu
{
    NSString *dirPath = [NSString stringWithFormat:@"%@/dir", path];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    if (![fm fileExistsAtPath:dirPath]){
        return TRUE;
    }
    
    NSArray *cmdList = [fm contentsOfDirectoryAtPath:dirPath error:nil];
    NSMutableArray *_cmdList = [[NSMutableArray alloc] init];
    
    for (NSString *f in cmdList) {
        NSString *path =[NSString stringWithFormat:@"%@/%@", dirPath,f];
        BOOL isDir = YES;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        [_cmdList addObject:f];
    }
    
    [_cmdList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 localizedStandardCompare:obj2];
    }];
    
    
    NSMenu *menuList = [[NSMenu alloc] initWithTitle:name];
    for (NSString *f in _cmdList) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", dirPath,f];
        BOOL isDir = YES;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        NSString *titlePath = @"";
        if ([transmit isEqualToString:@""]){
            titlePath = [NSString stringWithFormat:@"%@/dir/%@",name,f];
        } else {
            titlePath =[NSString stringWithFormat:@"%@/dir/%@",transmit,f];
        }
        
        if (![self checkMenuDir:f transmit:titlePath path:path menu:menuList])
        {
            continue;
        }
        
        NSMenu *vMenu = [self getCmdMenu:titlePath];
        NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:f
                                                       action:@selector(cmdStatusSet:)
                                                keyEquivalent:@""];
        NSString *titleLog = [titlePath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        if ( [self checkCmdStatus:titleLog] ){
            vItem.state = 1;
        }
        [menuList addItem:vItem];
        [menuList setSubmenu:vMenu forItem:vItem];
    }
    
    NSMenuItem *listItem = [[NSMenuItem alloc] initWithTitle:name
                                                      action:NULL
                                               keyEquivalent:@""];
    [menu addItem:listItem];
    [menu setSubmenu:menuList forItem:listItem];
    
    return FALSE;
}

-(void)initCmdList
{
    [cmd.submenu removeAllItems];
    
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSString *cmdDir = [NSString stringWithFormat:@"%@bin/reinstall/cmd", rootDir];
    NSArray *cmdList = [fm contentsOfDirectoryAtPath:cmdDir error:nil];
    
    NSMutableArray *_cmdList = [[NSMutableArray alloc] init];
    for (NSString *f in cmdList) {
        NSString *path =[NSString stringWithFormat:@"%@/%@", cmdDir,f];
        BOOL isDir = YES;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        [_cmdList addObject:f];
    }
    
    [_cmdList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 localizedStandardCompare:obj2];
    }];
    
    for (NSString *f in _cmdList) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", cmdDir,f];
        BOOL isDir = YES;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        if (![self checkMenuDir:f transmit:@"" path:path menu:cmd.submenu])
        {
            continue;
        }
        
        NSMenu *vMenu = [self getCmdMenu:f];
        NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:f
                                                       action:@selector(cmdStatusSet:)
                                                keyEquivalent:@""];
        if ( [self checkCmdStatus:f] ){
            vItem.state = 1;
        }
        [cmd.submenu addItem:vItem];
        [cmd.submenu setSubmenu:vMenu forItem:vItem];
    }
    
    [cmd.submenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"refresh"
                                                     action:@selector(cmdRefresh:)
                                              keyEquivalent:@""];
    refresh.state = 1;
    [cmd.submenu addItem:refresh];
}

-(void)cmdRefresh:(id)sender
{
    [self initCmdList];
}

-(void)cmdInstall:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSString *title = [self getMenuCmdPath:cMenu];
    [self cmdInAndUnin:@"install" version:title];
}

-(void)cmdUninstall:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSString *title = [self getMenuCmdPath:cMenu];
    [self cmdInAndUnin:@"uninstall" version:title];
}

-(void)cmdInAndUnin:(NSString *)sh version:(NSString *)version
{
    NSString *versionLog = [version stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/%@.sh", rootDir, version, sh];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if ([NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/cmd_%@_%@.log", rootDir, versionLog,sh];
    NSString *cmd = [NSString stringWithFormat:@"%@ 1>> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:0 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)cmdStatusSet:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSString *title =  [self getMenuMainCmdPath:cMenu];
    NSString *tlog = [title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *rootDir = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSString *lock = [NSString stringWithFormat:@"%@bin/tmp/cmd/%@.lock", rootDir, tlog];
    
    NSString *name = @"start";
    if ([NSCommon fileIsExists:lock]){
        name = @"stop";
    }
    
    NSString *doSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/%@.sh", rootDir, title,name];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if ([NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/cmd_%@_%@.log", rootDir, tlog, name];
    if (![fm fileExistsAtPath:log]){
        [@"" writeToFile:log atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSString *cmd = [NSString stringWithFormat:@"%@ 1>> %@ 2>&1", doSh,log];
    if ([NSCommon fileIsExists:doSh]){
        [NSCommon delayedRun:0 callback:^{
            [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
            [self userCenter:[NSString stringWithFormat:@"执行[%@服务%@脚本]成功!", title,name]];
        }];
        
        if ([NSCommon fileIsExists:lock]){
            [fm removeItemAtPath:lock error:NULL];
        } else {
            [fm createFileAtPath:lock contents:NULL attributes:NULL];
        }
    }
    
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [self initCmdList];
}


-(void)cmdReload:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSString *rootDir = [NSCommon getRootDir];
    NSString *title =  [self getMenuCmdPath:cMenu];
    NSString *tlog = [title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    NSString *name = @"reload";
    NSString *doSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/%@.sh", rootDir, title,name];
    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/cmd_%@_%@.log", rootDir, tlog, name];
    NSString *cmd = [NSString stringWithFormat:@"%@ 1>> %@ 2>&1", doSh,log];
    if ([NSCommon fileIsExists:doSh]){
        
        [NSCommon delayedRun:0 callback:^{
            [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
            [self userCenter:[NSString stringWithFormat:@"执行[%@服务%@脚本]成功!", title,name]];
        }];
        
        [NSCommon delayedRun:1 callback:^{
            [self openFile:log];
        }];
        
    } else {
        [self userCenter:[NSString stringWithFormat:@"CMD[%@](%@)脚本不存在!",title,name]];
    }
    [self initCmdList];
}

-(NSString *)getMenuCmdPath:(NSMenuItem *)menu
{
    NSMenuItem *pMenu=[menu parentItem];
    NSString *path = pMenu.title;
    
    for (;;) {
        pMenu = [pMenu parentItem];
        if (!pMenu){
            break;
        }
        
        if ([pMenu.title isEqualToString:@"CMD"]){
            break;
        }
        
        path = [NSString stringWithFormat:@"%@/dir/%@",pMenu.title,path];
    }
    
    return path;
}

-(NSString *)getMenuMainCmdPath:(NSMenuItem *)menu
{
    NSMenuItem *pMenu=[menu parentItem];
    NSString *path = menu.title;
    
    for (;;) {
        if ([pMenu.title isEqualToString:@"CMD"]){
            break;
        }
        
        path = [NSString stringWithFormat:@"%@/dir/%@",pMenu.title,path];
        pMenu = [pMenu parentItem];
        
        if (!pMenu){
            break;
        }
    }
    return path;
}

-(void)cmdDir:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSString *pathTitle = [self getMenuCmdPath:cMenu];
    
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    [NSCommon delayedRun:0 callback:^{
        NSString *str = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@",rootDir,pathTitle];
        BOOL isDir = YES;
        if ([fm fileExistsAtPath:str isDirectory:&isDir]){
            [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];
        } else {
            [self userCenter:[NSString stringWithFormat:@"CMD%@目录不存在!",pathTitle]];
        }
    }];
}

#pragma mark - 初始化PHP版本列表 -

-(NSMenu*)getPhpExtendsMenu:(NSString *) v extlib:(NSMutableDictionary *)extlib
{
//    NSLog(@"---log %@", v);
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSMenu *extListMenu = [[NSMenu alloc] initWithTitle:v];
    
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *extDir = [NSString stringWithFormat:@"%@bin/reinstall/extensions", rootDir];
    NSArray *extList = [fm contentsOfDirectoryAtPath:extDir error:nil];
    
    NSString *content = @"";
    NSString *phpDir = [NSString stringWithFormat:@"%@bin/php/php%@", rootDir, v];
    
    if ([NSCommon fileIsExists:phpDir]){
        NSString *phpIni = [NSString stringWithFormat:@"%@bin/php/php%@/etc/php.ini", rootDir, v];
        
        if (![NSCommon fileIsExists:phpIni]){
            [self userCenter:[NSString stringWithFormat:@"PHP%@配置文件不存在!", v]];
        }
        
        content = [self getPhpIniContent:v];
        if ([content isEqualToString:@""])
        {
            [self userCenter:[NSString stringWithFormat:@"PHP%@INI配置文件读取错误!", v]];
        }
    }
    
    NSMutableArray *_extList = [[NSMutableArray alloc] init];
    for (NSString *e in extList) {
        NSString *path =[NSString stringWithFormat:@"%@/%@", extDir,e];
        BOOL isDir;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        [_extList addObject:e];
    }
    
    NSArray *__extList;
    __extList = [_extList sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2){
        const char  * o1 = [[obj1 substringToIndex:1] UTF8String];
        const char  * o2 = [[obj2 substringToIndex:1] UTF8String];
        if (strcmp(o1, o2)>-1){
            return YES;
        }
        return NO;
    }];
    
    for (NSString *ee in __extList) {
        //判断是否在支持的列表中 start
        if (![[extlib allKeys] containsObject:ee]) {
            continue;
        }
        
        NSArray *lib_version = [extlib objectForKey:ee];
        
        if (![lib_version containsObject:v]) {
            continue;
        }
        // NSLog(@"ext:%@:%@:%@", v,ee,lib_version);
        //判断是否在支持的列表中 end
        
        NSMenu *extMenu = [[NSMenu alloc] initWithTitle:v];
        [extMenu addItemWithTitle:@"Install" action:@selector(phpExtInstall:) keyEquivalent:@""];
        [extMenu addItemWithTitle:@"UnInstall" action:@selector(phpExtUninstall:) keyEquivalent:@""];
        
        NSMenuItem *extItem = [[NSMenuItem alloc] initWithTitle:ee
                                                         action:@selector(phpExtStatusSet:)
                                                  keyEquivalent:@""];
        if ([self checkPhpExtIsLoadByContent:content extName:ee]){
            extItem.state = 1;
            
            NSString *reloadSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/%@/reload.sh", rootDir, v,ee];
            if ([NSCommon fileIsExists:reloadSh]){
                [extMenu addItemWithTitle:@"Reload" action:@selector(phpExtReload:) keyEquivalent:@""];
            }
        }
        [extMenu addItemWithTitle:@"Dir" action:@selector(phpExtDir:) keyEquivalent:@""];
        
        [extListMenu addItem:extItem];
        [extListMenu setSubmenu:extMenu forItem:extItem];
    }
    return extListMenu;
}

-(void)phpExtInstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    NSMenuItem *ppMenu=[pMenu parentItem];
    NSMenuItem *pppMenu=[ppMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/extensions/%@/install.sh", rootDir,pMenu.title];
    
    if (![NSCommon fileIsExists:installSh]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展install脚本不存在!", pppMenu.title,pMenu.title]];
        return;
    }
    
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if (![NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@/php%@_ext_%@_install.log", logDir, pppMenu.title,pMenu.title];
    NSString *cmd = [NSString stringWithFormat:@"%@ %@ 1> %@ 2>&1", installSh,pppMenu.title,log];
    
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)phpExtUninstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    NSMenuItem *ppMenu=[pMenu parentItem];
    NSMenuItem *pppMenu=[ppMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/extensions/%@/uninstall.sh", rootDir,pMenu.title];
    
    if (![NSCommon fileIsExists:installSh]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展uninstall脚本不存在!", pppMenu.title,pMenu.title]];
        return;
    }
    
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if (![NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@/php%@_ext_%@_uninstall.log", logDir, pppMenu.title,pMenu.title];
    
    NSString *cmd = [NSString stringWithFormat:@"%@ %@ 1> %@ 2>&1", installSh,pppMenu.title,log];
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}
-(void)phpExtReload:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    NSMenuItem *ppMenu=[pMenu parentItem];
    NSMenuItem *pppMenu=[ppMenu parentItem];
    
    NSString *reloadSh = [NSString stringWithFormat:@"%@bin/reinstall/extensions/%@/reload.sh", rootDir,pMenu.title];
    
    if (![NSCommon fileIsExists:reloadSh]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展reload脚本不存在!", pppMenu.title,pMenu.title]];
        return;
    }
    
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    NSString *log = [NSString stringWithFormat:@"%@/php%@_ext_%@_reload.log", logDir, pppMenu.title,pMenu.title];
    NSString *cmd = [NSString stringWithFormat:@"%@ %@ 1> %@ 2>&1", reloadSh, pppMenu.title, log];
    
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
    
}
-(void)phpExtDir:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
//    NSMenuItem *ppMenu=[pMenu parentItem];
//    NSMenuItem *pppMenu=[ppMenu parentItem];
    
    [NSCommon delayedRun:0 callback:^{
        NSString *str = [NSString stringWithFormat:@"%@bin/reinstall/extensions/%@",rootDir,pMenu.title];
        BOOL isDir = YES;
        if ([fm fileExistsAtPath:str isDirectory:&isDir]){
            [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];
        } else {
            [self userCenter:[NSString stringWithFormat:@"PHP扩展脚本%@目录不存在!",pMenu.title]];
        }
    }];
}

-(NSString *)getPhpIniContent:(NSString*)version
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *phpIni = [NSString stringWithFormat:@"%@bin/php/php%@/etc/php.ini", rootDir, version];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:phpIni encoding:NSUTF8StringEncoding error:&error];
    if (error != nil)
    {
        return @"";
    }
    return content;
}

-(BOOL)checkPhpExtIsLoadByContent:(NSString *)content extName:(NSString *)extName
{
    NSString *pattern = [NSString stringWithFormat:@"\\[%@\\]", extName];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:NULL];
    
    NSArray *results = [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    if (results.count == 0){
        return NO;
    }
    return YES;
}

-(BOOL)checkPhpExtIsLoad:(NSString*)version extName:(NSString *)extName
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *phpIni = [NSString stringWithFormat:@"%@bin/php/php%@/etc/php.ini", rootDir, version];
    
    if (![NSCommon fileIsExists:phpIni]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@配置文件不存在!", version]];
        return NO;
    }
    
    NSString *content = [self getPhpIniContent:version];
    if ([content isEqualToString:@""])
    {
        [self userCenter:[NSString stringWithFormat:@"PHP%@配置文件读取错误!", version]];
        return NO;
    }
    
    if (![self checkPhpExtIsLoadByContent:content extName:extName]){
        return NO;
    }
    return YES;
}

-(BOOL)checkPhpExtIsExist:(NSString*)version extName:(NSString *)extName
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *extFile = [NSString stringWithFormat:@"%@bin/php/php%@/lib/php/extensions", rootDir,version];
    NSLog(@"%@",extFile);
    return NO;
}

-(void)phpExtStatusSet:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    NSMenuItem *ppMenu=[pMenu parentItem];
    
    NSString *shName = @"load";
    if ([self  checkPhpExtIsLoad:ppMenu.title extName:cMenu.title])
    {
        shName = @"unload";
    }
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/%@/%@.sh", rootDir, ppMenu.title,cMenu.title, shName];
    if (![NSCommon fileIsExists:installSh]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展%@脚本不存在!", ppMenu.title,cMenu.title,shName]];
        return;
    }
    
    
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if (![NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@/php%@_ext_%@_%@.log", logDir, ppMenu.title,cMenu.title,shName];
    NSString *cmd = [NSString stringWithFormat:@"%@ %@ 1> %@ 2>&1", installSh,ppMenu.title,log];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
    
    [NSCommon delayedRun:0.2 callback:^{
        [self initPhpList];
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展%@脚本执行成功!", ppMenu.title,cMenu.title,shName]];
        [self phpFpmCmdReload:ppMenu.title];
    }];
}


-(BOOL)findEnv:(NSString *)title{

    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"MD_PHP_VER"] isEqualToString:title]
        && [[NSUserDefaults standardUserDefaults] boolForKey:@"MD_PHP_VER_LOAD"]
        ){
        return YES;
    }
    return NO;
}

-(NSMenu*)getPhpVerMenu:(NSString *)title extlib:(NSMutableDictionary *)extlib
{
    NSMenu *vMenu = [[NSMenu alloc] initWithTitle:title];
    
    [vMenu addItemWithTitle:@"Install" action:@selector(phpInstall:) keyEquivalent:@""];
    [vMenu addItemWithTitle:@"UnInstall" action:@selector(phpUninstall:) keyEquivalent:@""];
    
    NSMenuItem *phpCommand = [[NSMenuItem alloc] initWithTitle:@"Command" action:@selector(phpCommand:) keyEquivalent:@""];
    phpCommand.state = (int)[self findEnv:title];
    
    [vMenu addItem:phpCommand];
    if ( [self checkWebPHP:title] ){
        [vMenu addItemWithTitle:@"Reload" action:@selector(phpReload:) keyEquivalent:@""];
    }
    [vMenu addItemWithTitle:@"Dir" action:@selector(phpDir:) keyEquivalent:@""];
    [vMenu addItemWithTitle:@"Extends Dir" action:@selector(phpExtendsDir:) keyEquivalent:@""];
    
//    NSLog(@"init %@", @"ddd");
    NSMenu *extMenu = [self getPhpExtendsMenu:title extlib:extlib];
    NSMenuItem *extItem = [[NSMenuItem alloc] initWithTitle:@"Extends"
                                                     action:NULL
                                              keyEquivalent:@""];
    [vMenu addItem:extItem];
    [vMenu setSubmenu:extMenu forItem:extItem];
    return vMenu;
}

#pragma mark - 读取PHP依赖关系 -
-(NSMutableDictionary *)readPhpExtLib {
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *extensionsLibFile = [NSString stringWithFormat:@"%@bin/reinstall/extensions/lib.md", rootDir];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    if (![fm fileExistsAtPath:extensionsLibFile]){
        return result;
    }

    NSString *content = [NSString stringWithContentsOfFile:extensionsLibFile encoding:NSUTF8StringEncoding error:nil];
    content = [content stringByTrimmingCharactersInSet:
               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *list = [content componentsSeparatedByString:@"\n"];
    

    for (int i=0; i<list.count; i++) {
        NSString *dep =  [list[i] stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *dep_list = [dep componentsSeparatedByString:@"|"];
        if (dep_list.count < 2){
            continue;
        }
        NSMutableArray *dep_version = [[NSMutableArray alloc] init];
        
        NSString *libname = [dep_list[0] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
        NSString *version =[dep_list[1] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *dep_version_t = [version componentsSeparatedByString:@","];

        for (int i=0; i<dep_version_t.count; i++) {
            NSString *version_t = [dep_version_t[i] stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [dep_version addObject:version_t];
        }
        [result setObject:dep_version forKey:libname];
    }
    return result;
}

-(void)initPhpList
{
    [phpVer.submenu removeAllItems];
    
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSString *phpDir = [NSString stringWithFormat:@"%@bin/reinstall", rootDir];
    
    NSArray *phpVlist = [fm contentsOfDirectoryAtPath:phpDir error:nil];
    NSInteger i = 1;
    
    
    NSMutableArray *_phpVlist = [[NSMutableArray alloc] init];
    for (NSString *f in phpVlist) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", phpDir,f];
        BOOL isDir;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        
        if([f hasPrefix:@"php"]){
            NSString *v = [f stringByReplacingOccurrencesOfString:@"php" withString:@""];
            [_phpVlist addObject:v];
        }
    }
    
    [_phpVlist sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 intValue]>[obj2 intValue]){
            return YES;
        }
        return NO;
    }];
    
    
    NSMutableDictionary *extlib = [self readPhpExtLib];
    for (NSString *f in _phpVlist) {
        NSMenu *vMenu = [self getPhpVerMenu:f extlib:extlib];
        
        NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:f
                                                       action:@selector(phpStatusSet:)
                                                keyEquivalent:[NSString stringWithFormat:@"%ld", i]];
        if ( [self checkWebPHP:f] ){
            vItem.state = 1;
        }
        [phpVer.submenu addItem:vItem];
        [phpVer.submenu setSubmenu:vMenu forItem:vItem];
        i++;
    }
    
    [phpVer.submenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"refresh"
                                                     action:@selector(phpRefresh:)
                                              keyEquivalent:[NSString stringWithFormat:@"%d", 0]];
    refresh.state = 1;
    [phpVer.submenu addItem:refresh];
}

-(void)phpInstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/install.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    
    if (![fm fileExistsAtPath:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@/php_%@_install.log", logDir, pMenu.title];
    
    NSString *cmd = [NSString stringWithFormat:@"%@ 1> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:2 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)phpUninstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/uninstall.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    
    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/php_%@_uninstall.log", rootDir, pMenu.title];
    [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    NSString *cmd = [NSString stringWithFormat:@"%@ 1>> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)phpCommand:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    [[NSUserDefaults standardUserDefaults] setObject:pMenu.title forKey:@"MD_PHP_VER"];
    if (cMenu.state){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MD_PHP_VER_LOAD"];
             
        [NSCommon delayedRun:0 callback:^{
            NSString *unloadEnv = [NSString stringWithFormat:@"%@bin/reinstall/unload_env.sh %@ > %@bin/logs/reinstall/unload_env.log", rootDir, pMenu.title,rootDir];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", unloadEnv, nil]] waitUntilExit];
        }];
    } else{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MD_PHP_VER_LOAD"];
        
        [NSCommon delayedRun:0 callback:^{
            
            NSString *loadEnv = [NSString stringWithFormat:@"%@bin/reinstall/load_env.sh %@ > %@bin/logs/reinstall/load_env.log", rootDir, pMenu.title, rootDir];
            [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", loadEnv, nil]] waitUntilExit];
            
            sleep(1);
            [[NSWorkspace sharedWorkspace] launchApplication:@"Terminal"];
        }];
    }
    
    [self phpRefresh:sender];
}

-(void)phpReload:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    [NSCommon delayedRun:0 callback:^{
        [self phpFpmReload:pMenu.title];
    }];
}

-(void)phpDir:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    [NSCommon delayedRun:0 callback:^{
        NSString *str = [NSString stringWithFormat:@"%@bin/php/php%@",rootDir,pMenu.title];
        BOOL isDir = YES;
        if ([fm fileExistsAtPath:str isDirectory:&isDir]){
            [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];
        } else {
            [self userCenter:[NSString stringWithFormat:@"PHP%@目录不存在!",pMenu.title]];
        }
    }];
}

-(void)phpExtendsDir:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    [NSCommon delayedRun:0 callback:^{
        NSString *str = [NSString stringWithFormat:@"%@bin/php/php%@/lib/php/extensions",rootDir,pMenu.title];
        NSArray *findExt = [fm contentsOfDirectoryAtPath:str error:nil];
        
        NSString *findExtDir = @"";
        for (NSString *f in findExt) {
            if([f hasPrefix:@"no-debug-non-zts"]){
                findExtDir = [NSString stringWithFormat:@"%@/%@", str, f];
            }
        }
        
        if ([findExtDir isEqualToString:@""]){
            [self userCenter:[NSString stringWithFormat:@"PHP%@安装不正确,请重新安装!",pMenu.title]];
            return;
        }
        
        
        BOOL isDir = YES;
        if ([fm fileExistsAtPath:findExtDir isDirectory:&isDir]){
            [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:findExtDir, nil]] waitUntilExit];
        } else {
            [self userCenter:[NSString stringWithFormat:@"PHP扩展%@目录不存在!",pMenu.title]];
        }
    }];
}

-(void)phpRefresh:(id)sender
{
    [self initPhpList];
}

#pragma 启动当前PHP-FPM
-(void)phpFpmCmdStart:(NSString *)version
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, version];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
}

#pragma 停止当前PHP-FPM
-(void)phpFpmCmdStop:(NSString *)version
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/php/status.sh %@ stopone", rootDir, version];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
}


-(void)phpFpmCmdReload:(NSString *)version
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/php/status.sh %@ reload", rootDir, version];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
}


-(void)phpFpmTrigger:(NSString *)version
{
    if ( [self checkWebPHP:version] ){
        [self phpFpmCmdStop:version];
        [self rmPHPSockFile:version];
        [self userCenter:[NSString stringWithFormat:@"执行[PHP%@-FPM停止]成功!", version]];
    } else {
        [self phpFpmCmdStart:version];
        [self userCenter:[NSString stringWithFormat:@"执行[PHP%@-FPM启动]成功!", version]];
    }
}

-(void)phpFpmReload:(NSString *)version
{
    if ( [self checkWebPHP:version] ){
        [self phpFpmCmdReload:version];
        [self userCenter:[NSString stringWithFormat:@"执行[PHP%@-FPM重启]成功!", version]];
    }
}

-(void)phpStatusSet:(id)sender {
    
    NSString *rootDir = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSMenuItem *cItem = (NSMenuItem *)sender;
    
    NSString *cPhpVer = [cItem title];
    NSString *phpDir = [NSString stringWithFormat:@"%@bin/php/php%@", rootDir, cPhpVer];
    
    if (![fm fileExistsAtPath:phpDir]){
        NSString *notice = [NSString stringWithFormat:@"PHP-%@没有安装,请先安装再使用!!", cPhpVer];
        [self userCenter:notice];
        return;
    }
    
    [NSCommon delayedRun:1 callback:^{
        [self phpFpmTrigger:cPhpVer];
        [NSCommon delayedRun:0.5 callback:^{
            [self phpRefresh:sender];
        }];
    }];
}
#pragma mark - 初始化PHP版本列表-END -

#pragma mark - 初始化MYSQL版本列表 -
-(void)initMySQLList
{
    [mysqlVer.submenu removeAllItems];
    
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSString *mysqlDir = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql", rootDir];
    
    NSArray *mysqlVlist = [fm contentsOfDirectoryAtPath:mysqlDir error:nil];
    NSInteger i = 1;
    
    NSArray *letter = @[@"0",@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"j",@"k",@"m",@"q",@"x",@"y",@"z"];
    
    
    NSMutableArray *_mysqlVlist = [[NSMutableArray alloc] init];
    for (NSString *f in mysqlVlist) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", mysqlDir,f];
        BOOL isDir;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        
        if([f hasPrefix:@"mysql"]){
            NSString *v = [f stringByReplacingOccurrencesOfString:@"mysql" withString:@""];
            [_mysqlVlist addObject:v];
        }
    }

    [_mysqlVlist sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 intValue]>[obj2 intValue]){
            return YES;
        }
        return NO;
    }];
    
    for (NSString *f in _mysqlVlist) {
        NSMenu *vMenu = [self getMysqlVerMenu:f];
        
        NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:f
                                                       action:@selector(mysqlStatusSet:)
                                                keyEquivalent:[NSString stringWithFormat:@"%@", [letter objectAtIndex:i]]];
        if ( [self checkMysqlStatus:f] ){
            vItem.state = 1;
        }
        [mysqlVer.submenu addItem:vItem];
        [mysqlVer.submenu setSubmenu:vMenu forItem:vItem];
        i++;
    }
    
    [mysqlVer.submenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"refresh"
                                                     action:@selector(mysqlRefresh:)
                                              keyEquivalent:@"!"];
    refresh.state = 1;
    [mysqlVer.submenu addItem:refresh];
    
}

-(void)mysqlRefresh:(id)sender
{
    [self initMySQLList];
}

-(void)mysqlStatusSet:(id)sender {
    
    NSString *rootDir = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSMenuItem *cItem = (NSMenuItem *)sender;
    
    NSString *myVer = [cItem title];
    NSString *phpDir = [NSString stringWithFormat:@"%@bin/mysql/mysql%@", rootDir, myVer];
    
    if (![fm fileExistsAtPath:phpDir]){
        NSString *notice = [NSString stringWithFormat:@"MYSQL-%@没有安装,请先安装再使用!!", myVer];
        [self userCenter:notice];
        return;
    }
    
    [NSCommon delayedRun:1 callback:^{
        [self mysqlTrigger:myVer];
        [NSCommon delayedRun:1 callback:^{
            [self mysqlRefresh:sender];
        }];
    }];
}

-(NSMenu*)getMysqlVerMenu:(NSString *)title
{
    NSMenu *vMenu = [[NSMenu alloc] initWithTitle:title];
    
    [vMenu addItemWithTitle:@"Install" action:@selector(mysqlInstall:) keyEquivalent:@""];
    [vMenu addItemWithTitle:@"UnInstall" action:@selector(mysqlUninstall:) keyEquivalent:@""];

    if ( [self checkMysqlStatus:title] ){
        [vMenu addItemWithTitle:@"Reload" action:@selector(mysqlReload:) keyEquivalent:@""];
    }
    [vMenu addItemWithTitle:@"Dir" action:@selector(mysqlDir:) keyEquivalent:@""];
    return vMenu;
}


-(void)mysqlDir:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    [NSCommon delayedRun:0 callback:^{
        NSString *str = [NSString stringWithFormat:@"%@bin/mysql/mysql%@",rootDir,pMenu.title];
        BOOL isDir = YES;
        if ([fm fileExistsAtPath:str isDirectory:&isDir]){
            [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:str, nil]] waitUntilExit];
        } else {
            [self userCenter:[NSString stringWithFormat:@"MYSQL%@目录不存在!",pMenu.title]];
        }
    }];
}

-(BOOL)checkMysqlStatus:(NSString *)ver
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *path = [NSString stringWithFormat:@"%@bin/mysql/mysql%@/data/mysql.pid", rootDir,ver];
//    NSLog(@"mysql:%@",path);
    return [fm fileExistsAtPath:path];
}

-(void)mysqlTrigger:(NSString *)version
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *phpDir = [NSString stringWithFormat:@"%@bin/mysql/mysql%@", rootDir, version];
    
    if (![fm fileExistsAtPath:phpDir]){
        NSString *notice = [NSString stringWithFormat:@"MYSQL-%@没有安装,请先安装再使用!!", version];
        [self userCenter:notice];
        return;
    }
    
    if ( [self checkMysqlStatus:version] ){
        [self mysqlCmdStop:version];
        [self userCenter:[NSString stringWithFormat:@"停止MYSQL%@成功!", version]];
    } else {
        [self mysqlCmdStart:version];
        [self userCenter:[NSString stringWithFormat:@"启动MYSQL%@成功!", version]];
    }

}

#pragma 启动当前MYSQL
-(void)mysqlCmdStart:(NSString *)version
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql/mysql%@/start.sh", rootDir, version];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
}

#pragma 停止当前MYSQL
-(void)mysqlCmdStop:(NSString *)version
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql/mysql%@/stop.sh", rootDir, version];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
}

-(void)mysqlReload:(id)sender
{
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    NSString *myVer = [pMenu title];
    
    
    NSString *rootDir = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *cmd = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql/mysql%@/reload.sh", rootDir, myVer];
    
    if ([fm fileExistsAtPath:cmd]){
        [self userCenter:[NSString stringWithFormat:@"执行重启MYSQL%@成功!", myVer]];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
    } else {
        [self userCenter:[NSString stringWithFormat:@"重启MYSQL%@文件不存在!", myVer]];
    }
}

-(void)mysqlInstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql/mysql%@/install.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    
    if (![fm fileExistsAtPath:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    NSString *log = [NSString stringWithFormat:@"%@/mysql_%@_install.log", logDir, pMenu.title];
    
    NSString *cmd = [NSString stringWithFormat:@"%@ 1> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:2 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)mysqlUninstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];
    
    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/mysql/mysql%@/uninstall.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    
    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/mysql_%@_uninstall.log", rootDir, pMenu.title];
    [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    NSString *cmd = [NSString stringWithFormat:@"%@ 1>> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:1 callback:^{
        [self openFile:log];
    }];
    
    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}


#pragma mark - 初始化MYSQL版本列表-END -

-(void)selfphpMsgStart:(NSNotification *)sender {
    NSDictionary *dic = sender.userInfo;
    NSString *ver =[dic objectForKey:@"ver"];
    [self userCenter:[NSString stringWithFormat:@"PHP%@检测未启动，已执行启动!",ver]];
}

#pragma mark - 程序加载时执行 -
- (void)applicationWillUpdate:(NSNotification *)notification{
    [self initCmdList];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self installHelp];
    
    //初始化php版本信息
    [NSCommon setCommonConfig:PHP_C_VER_KEY value:@"55"];
    [NSCommon setCommonConfig:PHP_S_VER_KEY value:@"71"];
    [NSCommon setCommonConfig:MYSQL_C_VER_KEY value:@"80"];
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
    
    NSString *rootDir = [NSCommon getRootDir];
    
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if ([NSCommon fileIsExists:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    [self initCmdList];
    [self initPhpList];
    [self initMySQLList];
    
    [self checkWebStatus];
    
    [self checkRedisStatus];
    [self checkMongoStatus];
    [self checkMemcachedStatus];
    [self checkMySQLOnStatus];
    
    [self setBarStatus];
    
    NSString *isos = [NSCommon getCommonConfig:@"isOpenAfterStart"];
    if ([isos isEqualTo:@"1"]) {
        sleep(1);
        [self startWebService];
    }
    
    //消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfReStart) name: @"reloadSVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfphpMsgStart:) name: @"startPhpVerInChange" object:nil];
}

-(void) applicationWillBecomeActive:(NSNotification *)notification
{
    [self initCmdList];
    [self initPhpList];
    [self initMySQLList];
    
    [self checkWebStatus];
    
    [self checkRedisStatus];
    [self checkMongoStatus];
    [self checkMemcachedStatus];
    [self checkMySQLOnStatus];
    
}

#pragma mark - 点击dock应用图标重新弹出主窗口
-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                   hasVisibleWindows:(BOOL)flag{
    if (!flag){
        [NSApp activateIgnoringOtherApps:NO];
        [self.window makeKeyAndOrderFront:self];
    }
    return YES;
}

#pragma mark - 程序退出时执行
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    NSString *iseall = [NSCommon getCommonConfig:@"isExitAfterCloseAll"];
    if ([iseall isEqualTo:@"1"]) {
        sleep(1);
        [self stopWebService];
    }
    
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
}
@end


