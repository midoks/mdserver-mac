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
    [alert setAlertStyle:NSInformationalAlertStyle];
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
    NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", app_dir];
    NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", app_dir];
    NSString *ss = [NSString stringWithFormat:@"%@Contents/Resources/ss", app_dir];
    NSString *root_dir = [NSCommon getRootDir];
    
    NSString *redis = [NSString stringWithFormat:@"%@bin/redis.sh", root_dir];
    NSArray *list = [[NSArray alloc] initWithObjects:addhost, removehost, ss, redis, nil];
    
    if (self->_authRef) {
        //NSLog(@"ok");
        return true;
    }else{
        UInt32 count = (UInt32)[list count];
        AuthorizationItem authItem[count];
        AuthorizationRights authRights;
        AuthorizationFlags flags  = kAuthorizationFlagDefaults |
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
        NSLog(@"AuthorizationExecuteWithPrivileges failed!:%d", status_exe);
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

- (IBAction)showNginxLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *nginx_access_log = [NSString stringWithFormat:@"%@/bin/openresty/nginx/logs/access.log", root];
    
    if ([NSCommon fileIsExists:nginx_access_log]) {
        [self openFile:nginx_access_log];
    }else{
        [NSCommon alert:@"Nginx日志暂时不存在"];
    }
}

- (IBAction)showPhpFpmLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
    NSString *php_fpm_log = [NSString stringWithFormat:@"%@/bin/php/%@/var/log/php-fpm.log", root, php_version];
    
    if ([NSCommon fileIsExists:php_fpm_log]){
        [self openFile:php_fpm_log];
    }else{
        [NSCommon alert:@"PHP-FPM日志暂时不存在"];
    }
}

- (IBAction)showMysqlLog:(id)sender {
    NSString *root = [NSCommon getRootDir];
    NSString *mysql_error_log = [NSString stringWithFormat:@"%@/bin/mysql/data/mysql.log", root];
    
    if ([NSCommon fileIsExists:mysql_error_log]){
        [self openFile:mysql_error_log];
    }else{
        [NSCommon alert:@"MySQL日志暂时不存在"];
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
    NSString *appDir  = [NSCommon getAppDir];
    NSString *rootDir   = [NSCommon getRootDir];
    NSString *title = pStartTitle.stringValue;
    
    if ([title isEqual:@"start"]) {
        
        NSString *isflog = [NSCommon getCommonConfig:@"isStartAfterFlushLog"];
        if ([isflog isEqualTo:@"1"]) {
            [self startFlushLogContent];
        }
        
        NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", appDir];
        [self AuthorizeExeCmd:addhost];
        
        [self startConfReplaceString];
        sleep(0.5);
        
        NSString *nginx = [NSString stringWithFormat:@"%@bin/startNginx.sh", rootDir];
        [self AuthorizeExeCmd:nginx];
        
        NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
        NSString *php = [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, php_version];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", php, nil]] waitUntilExit];
        
        [self userCenter:@"启动成功"];
    }
}

#pragma mark - 停止服务 -
- (void)stopWebService
{
    NSString *rootDir = [NSCommon getRootDir];
    NSString *appDir = [NSCommon getAppDir];
    NSString *title = pStartTitle.stringValue;
    
    if([title isEqual:@"stop"]){
        
        NSString *nginx_php = [NSString stringWithFormat:@"%@bin/stopNginx.sh", rootDir];
        [self AuthorizeExeCmd:nginx_php];
        
        NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
        NSString *php = [NSString stringWithFormat:@"%@bin/php/status.sh %@ stop", rootDir, php_version];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", php, nil]] waitUntilExit];
        
        NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", appDir];
        [self AuthorizeExeCmd:removehost];
        
        //sleep(1);
        [self stopConfReplaceString];
        
        [self userCenter:@"停止成功"];
    }
}

#pragma mark - 重置服务 -
-(IBAction)reloadSVC:(id)sender
{
    if ([self AuthorizeCreate]){
        NSString *rootDir = [NSCommon getRootDir];
        NSString *reloadSVC = [NSString stringWithFormat:@"%@bin/reloadSVC.sh", rootDir];
        [self AuthorizeExeCmd:reloadSVC];
    }
}

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

#pragma mark - 按钮启动 -
- (IBAction)start:(id)sender {
    if ([self AuthorizeCreate]){
        [self selfStart];
    }
}

#pragma mark - 重新启动 -
-(void)selfReStart
{
    if ([self AuthorizeCreate]){
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
            
            NSString *rootDir = [NSCommon getRootDir];
            NSString *appDir  = [NSCommon getAppDir];
            
            NSString *removehost = [NSString stringWithFormat:@"%@Contents/Resources/removehost", appDir];
            [self AuthorizeExeCmd:removehost];
            NSString *addhost = [NSString stringWithFormat:@"%@Contents/Resources/addhost", appDir];
            [self AuthorizeExeCmd:addhost];
            
            
            [self stopConfReplaceString];
            [self startConfReplaceString];
            
            //NSLog(@"rootDir:%@",rootDir);
            NSString *reload = [NSString stringWithFormat:@"%@bin/reloadSVC.sh", rootDir];
            [self AuthorizeExeCmd:reload];
            
        }
        
        [self delayedRun:1.0f callback:^{
            self->_StartServerStatus = @"ended";
            [self checkWebStatus];
            [self->pProgress setHidden:YES];
            [self->pProgress stopAnimation:nil];
        }];
    }
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
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/phpMyAdmin/"]];
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
    NSString *rootDir   = [NSCommon getRootDir];
    if (_mMySQLButton.state == 1) {
        NSString *mysql = [NSString stringWithFormat:@"%@bin/start.sh mysql", rootDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", mysql, nil]] waitUntilExit];
        sleep(3);
    } else {
        NSString *mysql = [NSString stringWithFormat:@"%@bin/stop.sh mysql", rootDir];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", mysql, nil]] waitUntilExit];
    }
    
    [self checkMySQLStatus];
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
-(BOOL)checkMySQLStatus
{
    NSString *path = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    path = [NSString stringWithFormat:@"%@bin/mysql/data/mysql.pid", path];
    BOOL isStart =  [fm fileExistsAtPath:path];
    
    if(isStart){
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
//    BOOL p = [self checkWebPHP];
    
    if (n) {
        
        [pStartTitle setStringValue:@"stop"];
        [pStart setImage:[NSImage imageNamed:@"stop"]];
        //NSLog(@"stoping");
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"started"];
    }else{
        [pStartTitle setStringValue:@"start"];
        [pStart setImage:[NSImage imageNamed:@"start"]];
        [NSCommon setCommonConfig:@"WebServerStatus" value:@"stoped"];
    }
    
    if (n) {
        pNginxStatus.state = 1;
    }else{
        pNginxStatus.state = 0;
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


#pragma mark - 初始化CMD列表 -

-(NSMenu*)getCmdMenu:(NSString *)title
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    
    [menu addItemWithTitle:@"Install" action:@selector(cmdInstall:) keyEquivalent:@""];
    [menu addItemWithTitle:@"UnInstall" action:@selector(cmdUninstall:) keyEquivalent:@""];
    return menu;
}

-(void)initCmdList{
    
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *rootDir           = [NSCommon getRootDir];
    
    NSString *cmdDir = [NSString stringWithFormat:@"%@bin/reinstall/cmd", rootDir];
    NSArray *cmdList = [fm contentsOfDirectoryAtPath:cmdDir error:nil];
    NSInteger i = 1;
    
    [cmd.submenu addItem:[NSMenuItem separatorItem]];
    
    for (NSString *f in cmdList) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", cmdDir,f];
        BOOL isDir = YES;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
        
        NSMenu *vMenu = [self getCmdMenu:f];
        NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:f
                                                       action:@selector(cmdStatusSet:)
                                                keyEquivalent:@""];
        [cmd.submenu addItem:vItem];
        [cmd.submenu setSubmenu:vMenu forItem:vItem];
        
        i++;
    }
    [cmd.submenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"refresh"
                                                     action:@selector(cmdRefresh:)
                                              keyEquivalent:@""];
    refresh.state = 1;
    [cmd.submenu addItem:refresh];
    [cmd.submenu addItem:[NSMenuItem separatorItem]];
}

-(void)cmdRefresh:(id)sender
{
    [cmd.submenu removeAllItems];
    [self initCmdList];
}

-(void)cmdInstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];

    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/install.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];

    if (![fm fileExistsAtPath:logDir]){
        [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }

    NSString *log = [NSString stringWithFormat:@"%@/cmd_%@_install.log", logDir, pMenu.title];

    NSString *cmd = [NSString stringWithFormat:@"%@ 1> %@ 2>&1", installSh,log];
    [NSCommon delayedRun:0 callback:^{
        [self openFile:log];
    }];

    [NSCommon delayedRun:0 callback:^{
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    }];
}

-(void)cmdUninstall:(id)sender
{
    NSString *rootDir           = [NSCommon getRootDir];
    NSFileManager *fm = [NSFileManager  defaultManager];

    NSMenuItem *cMenu = (NSMenuItem*)sender;
    NSMenuItem *pMenu=[cMenu parentItem];

    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/cmd/%@/uninstall.sh", rootDir, pMenu.title];
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];

    NSString *log = [NSString stringWithFormat:@"%@bin/logs/reinstall/cmd_%@_uninstall.log", rootDir, pMenu.title];
    [fm createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:NULL error:NULL];

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
    NSLog(@"%@",@"phpStatusSet");
}


#pragma mark - 初始化PHP版本列表 -

-(NSMenu*)getPhpExtendsMenu:(NSString *) v
{
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSMenu *extListMenu = [[NSMenu alloc] initWithTitle:v];
    
    NSString *rootDir           = [NSCommon getRootDir];
    NSString *extDir = [NSString stringWithFormat:@"%@bin/reinstall/php%@", rootDir, v];
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
    
    for (NSString *e in extList) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", extDir,e];
        BOOL isDir;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }

        NSMenu *extMenu = [[NSMenu alloc] initWithTitle:v];
        [extMenu addItemWithTitle:@"Install" action:@selector(phpExtInstall:) keyEquivalent:@""];
        [extMenu addItemWithTitle:@"UnInstall" action:@selector(phpExtUninstall:) keyEquivalent:@""];
        NSMenuItem *extItem = [[NSMenuItem alloc] initWithTitle:e
                                                         action:@selector(phpExtStatusSet:)
                                                  keyEquivalent:@""];
        
        if ([self checkPhpExtIsLoadByContent:content extName:e]){
            extItem.state = 1;
        }
        
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
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/%@/install.sh", rootDir, pppMenu.title,pMenu.title];
    
    if (![NSCommon fileIsExists:installSh]){
        [self userCenter:[NSString stringWithFormat:@"PHP%@-%@扩展install脚本不存在!", pppMenu.title,pMenu.title]];
        return;
    }
    
    NSString *logDir = [NSString stringWithFormat:@"%@bin/logs/reinstall", rootDir];
    if (![fm fileExistsAtPath:logDir]){
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
    
    NSString *installSh = [NSString stringWithFormat:@"%@bin/reinstall/php%@/%@/uninstall.sh", rootDir, pppMenu.title,pMenu.title];
    
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
        [self->phpVer.submenu removeAllItems];
        [self initPhpList];
    }];
}


-(NSMenu*)getPhpVerMenu:(NSString *)title
{
    NSMenu *vMenu = [[NSMenu alloc] initWithTitle:title];
    
    [vMenu addItemWithTitle:@"Install" action:@selector(phpInstall:) keyEquivalent:@""];
    [vMenu addItemWithTitle:@"UnInstall" action:@selector(phpUninstall:) keyEquivalent:@""];
    
    NSMenu *extMenu = [self getPhpExtendsMenu:title];
    NSMenuItem *extItem = [[NSMenuItem alloc] initWithTitle:@"Extends"
                                                   action:@selector(phpInstall:)
                                            keyEquivalent:@""];
    [vMenu addItem:extItem];
    [vMenu setSubmenu:extMenu forItem:extItem];
    return vMenu;
}

-(void)initPhpList
{
    NSFileManager *fm = [NSFileManager  defaultManager];
    NSString *rootDir           = [NSCommon getRootDir];

    NSString *phpDir = [NSString stringWithFormat:@"%@bin/reinstall", rootDir];
    
    NSArray *phpVlist = [fm contentsOfDirectoryAtPath:phpDir error:nil];
    NSInteger i = 1;
    
    [phpVer.submenu addItem:[NSMenuItem separatorItem]];
    
    for (NSString *f in phpVlist) {
        
        NSString *path =[NSString stringWithFormat:@"%@/%@", phpDir,f];
        BOOL isDir;
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir){
            continue;
        }
    
        if([f hasPrefix:@"php"]){
            
            NSString *ver = [f stringByReplacingOccurrencesOfString:@"php" withString:@""];
            NSMenu *vMenu = [self getPhpVerMenu:ver];
            
            NSMenuItem *vItem = [[NSMenuItem alloc] initWithTitle:ver
                                                           action:@selector(phpStatusSet:)
                                                    keyEquivalent:[NSString stringWithFormat:@"%ld", i]];
            
            if ( [self checkWebPHP:ver] ){
                vItem.state = 1;
            }
            [phpVer.submenu addItem:vItem];
            [phpVer.submenu setSubmenu:vMenu forItem:vItem];
            
            i++;
        }
    }
    [phpVer.submenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"refresh"
                                                  action:@selector(phpRefresh:)
                                           keyEquivalent:[NSString stringWithFormat:@"%d", 0]];
    refresh.state = 1;
    [phpVer.submenu addItem:refresh];
    [phpVer.submenu addItem:[NSMenuItem separatorItem]];
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
    [NSCommon delayedRun:1 callback:^{
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


-(void)phpRefresh:(id)sender
{
    [phpVer.submenu removeAllItems];
    [self initPhpList];
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

    if ( [self checkWebPHP:cPhpVer] ){
        //停止当前PHP-FPM
        NSString *cmd = [NSString stringWithFormat:@"%@bin/php/status.sh %@ stop", rootDir, cPhpVer];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
    
        [self userCenter:@"PHP-FPM STOP OK!"];
    } else {
        //启动新PHP-FPM
        NSString *cmd = [NSString stringWithFormat:@"%@bin/php/status.sh %@ start", rootDir, cPhpVer];
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]] waitUntilExit];
        [self userCenter:@"PHP-FPM STRAT OK!"];
    }
    [self phpRefresh:sender];
}

#pragma mark - 程序加载时执行 -
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self initCmdList];
    [self initPhpList];
    
    [self checkWebStatus];
    
    [self checkRedisStatus];
    [self checkMongoStatus];
    [self checkMemcachedStatus];
    [self checkMySQLStatus];
    
    [self setBarStatus];
    
    NSString *isos = [NSCommon getCommonConfig:@"isOpenAfterStart"];
    if ([isos isEqualTo:@"1"]) {
        sleep(1);
        [self startWebService];
    }
    
    //初始化php版本信息
    NSString *php_version = [NSCommon getCommonConfig:PHP_C_VER_KEY];
    if (!php_version || [php_version isEqualToString:@""]) {
        [NSCommon setCommonConfig:PHP_C_VER_KEY value:@"php55"];
    }
    
    [NSCommon setCommonConfig:@"isOpenModMySQLPwdWindow" value:@"no"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfReStart) name: @"reloadSVC" object:nil];
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


