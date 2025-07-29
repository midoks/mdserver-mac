//
//  NSCommon.m
//  mdserver
//
//  Created by midoks on 15/1/26.
//  Copyright (c) 2015年 midoks All rights reserved.
//

#import "NSCommon.h"

@interface NSCommon()<NSUserNotificationCenterDelegate>

@end

@implementation NSCommon

#pragma mark - 弹出提示 -
+(void)alert:(NSString *)content
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setInformativeText:content];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
}

+(void)alert:(NSString *)content delayedClose:(float)t
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setInformativeText:content];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
    
    //[alert cl];
    
    [self delayedRun:t callback:^{
        [alert.window close];
    }];
}

#pragma mark 延迟执行
+(void)delayedRun:(float)t callback:(void(^)(void)) callback
{
    double delayInSeconds = t;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        callback();
    });
}

#pragma mark 只执行一次方法
+(void)runOneTime:(NSString *)sign run:(void(^)(void))run
{
    static NSMutableSet *executedSigns = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        executedSigns = [NSMutableSet set];
    });
    
    if (![executedSigns containsObject:sign]) {
        run();
        [executedSigns addObject:sign];
    }
    NSLog(@"Executed signs: %@", executedSigns);
}

#pragma mark 判断文件是否存在
+(BOOL)fileIsExists:(NSString *)absPathFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:absPathFile];
}

#pragma mark 打开文件
+(void)openFile:(NSString *)file
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[file];
    [task launch];
}

#pragma mark 获取进程执行结构
+(void)getProcessReturn:(NSString *)pathsh
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", pathsh];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    NSFileHandle *file = pipe.fileHandleForReading;
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Process output: %@", string);
    NSLog(@"Exit status: %d", task.terminationStatus);
}


#pragma mark 获取上一级目录
+(NSString *)getDirName:(NSString *)dirname
{
    NSArray *i = [dirname componentsSeparatedByString:@"/"];
    NSMutableArray *ii = [[NSMutableArray alloc] initWithArray:i];
    [ii removeLastObject];
    NSString *r = [ii componentsJoinedByString:@"/"];
    return r;
}

#pragma mark 获取app目录
+(NSString *)getAppDir
{
    char path[1024];
    unsigned size = 1024;
    
    _NSGetExecutablePath(path, &size);
    path[size] = '\0';
    
    NSString *str = [NSString stringWithFormat:@"%s", path];
    str = [NSString stringWithFormat:@"%@", str];
    
    str = [self getDirName:str];
    str = [self getDirName:str];
    str = [self getDirName:str];
    str = [NSString stringWithFormat:@"%@/", str];
    return str;
}

#pragma mark 获取运行根目录
+ (NSString *)getRootDir
{
//    char path[1024];
//    unsigned size = 1024;
//    
//    _NSGetExecutablePath(path, &size);
//    path[size] = '\0';
//    
//    NSString *str = [NSString stringWithFormat:@"%s", path];
//    str = [self getDirName:str];
//    str = [self getDirName:str];
//    str = [self getDirName:str];
//    str = [self getDirName:str];
//    
//    str = [NSString stringWithFormat:@"%@/mdserver/", str];
//    NSLog(@"debug:%@", str);
//    return str;
//    /Users/midoks/Library/Developer/Xcode/DerivedData
    NSString *root_path = [NSString stringWithFormat:@"/Applications/mdserver/%@", @""];
    return root_path;
}

+(NSString *)getBundleName{
    NSDictionary *dir = [[NSBundle mainBundle] infoDictionary];
    return [dir objectForKey:@"CFBundleName"];
}

+ (NSString *)getSupportDir
{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
//    NSString *appSupportDirectory = [paths objectAtIndex:0];
//    appSupportDirectory = [appSupportDirectory stringByAppendingFormat:@"/%@",@"mdserver"];
//    return appSupportDirectory;
    return @"/Library/Application\\ Support/mdserver";
}

+(BOOL)saveNginxConfig {
    
    [NSCommon setRemoveAllConfig];

    NSMutableArray *list = [NSMutableArray array];
    NSString *pathplist = [NSCommon getServerPlist];
//    NSString *pathplist = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
    NSMutableDictionary *listContent = [NSMutableDictionary dictionaryWithContentsOfFile:pathplist];
    
    for (NSMutableDictionary *k in listContent) {
        [list addObject:[listContent objectForKey:k]];
    }
    
    NSString *rootDir = [NSCommon getRootDir];
    NSString *vhost = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/vhost", rootDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    
    for (NSMutableDictionary *i in list) {
        
        if ([[i objectForKey:@"path"] isEqualToString:@""]){
            continue;
        }
        
        if ([[i objectForKey:@"port"] isEqualToString:@"8888"] && [[i objectForKey:@"hostname"] isEqualToString:@"localhost"])
        {
            continue;
        }
        
        //Check if there is a custom configuration
        NSString *serverName = [[i objectForKey:@"hostname"] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        NSString *own_host = [NSString stringWithFormat:@"%@%@", @"own_", serverName];
        NSString *own_conf = [NSString stringWithFormat:@"%@/%@.conf", vhost, own_host];
        
        //NSLog(@"%@",own_conf);
        if (![fm fileExistsAtPath:own_conf]){
            [NSCommon setConfigWithServerName:[i objectForKey:@"hostname"]
                                         port:[i objectForKey:@"port"]
                                         path:[i objectForKey:@"path"]
                                          php:[i objectForKey:@"php"]];
        }
    }
    return YES;
}

+(BOOL)setRemoveAllConfig
{
    NSString *str = [NSCommon getRootDir];
    NSString *vhost = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/vhost", str];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *list = [fm contentsOfDirectoryAtPath:vhost error:nil];
    
    for (NSString *i in list) {
        if ([i hasSuffix:@"conf"]) {
            NSString *temp = [i substringToIndex:4];
            if ([temp isEqualTo:@"tmp_"]) {
                NSString *removeFile = [NSString stringWithFormat:@"%@/%@", vhost,i];
                [fm removeItemAtPath:removeFile error:nil];
            }
        }
    }
    return YES;
}

+(BOOL)setConfigWithServerName:(NSString *)serverName port:(NSString *)port path:(NSString *)path php:(NSString *)php
{
    NSString *str = [NSCommon getRootDir];
    //vhost下配置
    NSString *vhost = [NSString stringWithFormat:@"%@bin/openresty/nginx/conf/vhost", str];
    NSString *rserverName = [serverName stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *nginx_vhost = [NSString stringWithFormat:@"%@/tmp_%@.conf" , vhost, rserverName];
    NSString *template = [NSString stringWithFormat:@"%@/conf.template", vhost];
    NSString *content = [NSString stringWithContentsOfFile:template encoding:NSUTF8StringEncoding error:nil];
    content = [content stringByReplacingOccurrencesOfString:@"{SERVERNAME}" withString:serverName];
    content = [content stringByReplacingOccurrencesOfString:@"{PORT}" withString:port];
    content = [content stringByReplacingOccurrencesOfString:@"{PATH}" withString:path];
    content = [content stringByReplacingOccurrencesOfString:@"MD:/" withString:str];
    content = [content stringByReplacingOccurrencesOfString:@"{VERSION}" withString:php];
    return [content writeToFile:nginx_vhost atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - 清空日志 -
+(BOOL)setFlushLog:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:path]){
        NSString *content = @"";
        [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return NO;
}


#pragma mark - Host文件操作 -
+(NSString *)getHostFileNeedContent{
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSString *pathplist = [self getServerPlist];
//    NSString *pathplist = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
    NSMutableDictionary *listContent = [[NSMutableDictionary alloc] initWithContentsOfFile:pathplist];
    
    for (NSMutableDictionary *k in listContent) {
        [list addObject:[listContent objectForKey:k]];
    }

    NSString *ret = @"";
    for (NSMutableDictionary *i in list) {
        if ([[i objectForKey:@"path"] isNotEqualTo:@""] && [[i objectForKey:@"hostname"] isNotEqualTo:@"localhost"]) {
            ret = [NSString stringWithFormat:@"\r\n%@\r\n127.0.0.1\t\t%@\t%@",
                   ret,
                   [i objectForKey:@"hostname"],
                   @"#MDserver Hosts Don`t Remove and Change"];
        }
    }
    //ret = [NSString stringWithFormat:@"%@\r\n##**MDserver Hosts Don`t Remove **##", ret];
    //NSLog(@"%@", ret);
    return ret;
}

+(NSString *)setHostFileNotNeedContent:(NSString *)content
{
    NSString *regexString = @".*#MDserver Hosts Don`t Remove and Change";
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:&error];
    NSString *ok = [regex stringByReplacingMatchesInString:content
                                                   options:NSMatchingReportProgress
                                                     range:NSMakeRange(0, content.length)
                                              withTemplate:@""];
    
    content = [ok stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //NSLog(@"error:%@", error);
    return content;
}

#pragma mark 全局设置
+(BOOL)setCommonConfig:(NSString *)key value:(id)value
{
    NSString *commonplist = [[NSBundle mainBundle] pathForResource:@"common" ofType:@"plist"];
    NSMutableDictionary *cContent = [[NSMutableDictionary alloc] initWithContentsOfFile:commonplist];
    [cContent setValue:value forKey:key];
    //NSLog(@"%@", cContent);
    return [cContent writeToFile:commonplist atomically:YES];
}

+(id)getCommonConfig:(NSString *)key{
    NSString *commomplist = [[NSBundle mainBundle] pathForResource:@"common" ofType:@"plist"];
    NSMutableDictionary *cContent = [[NSMutableDictionary alloc] initWithContentsOfFile:commomplist];
    return [cContent objectForKey:key];
}


#pragma mark 创建info文件
+(BOOL)makePhpInfo:(NSString *)path{
    //NSFileManager *fm = [NSFileManager defaultManager];
    NSString *phpinfo = @"<?php phpinfo();?>";
    
    NSError *error;
    BOOL rok = [phpinfo writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!rok) {
        [NSCommon alert:[error domain]];
    }
    return rok;
}

#pragma mark - 创建目录
+(void)createDirIfNoExist:(NSURL *)url{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [url path];
    if (![fm fileExistsAtPath:path]){
        [fm createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - 获取App支持的目录,不存在就自动创建
+(NSURL *)appSupportDirURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSURL *> *asPath = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSURL * appAsUrl = [asPath.firstObject URLByAppendingPathComponent:bundleID];
    
    [self createDirIfNoExist:appAsUrl];
    return appAsUrl;
}


+(NSString*)getServerPlist{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *dirUrl = [NSCommon appSupportDirURL];
    NSURL *writeURL = [dirUrl URLByAppendingPathComponent:@"server.plist"];
    
    if (![fm fileExistsAtPath:[writeURL path]]){
        NSString *serverList = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
        NSString *content = [NSString stringWithContentsOfFile:serverList encoding:NSUTF8StringEncoding error:nil];
        [content writeToURL:writeURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return  [writeURL path];
}

+(NSArray *)getAllPhpVer{
    NSMutableArray *tmp =[[NSMutableArray alloc] init];
    
    NSMutableDictionary *listContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[self getServerPlist]];
    for (id key in listContent){
        
        id obj = [listContent objectForKey:key];
        NSString *php     = [obj objectForKey:@"php"];
        if ([php intValue]>50){
            [tmp addObject:php];
        }
    }
    NSArray *data = [[NSSet setWithArray:tmp] allObjects];
    return  data;
}

@end
