//
//  NSCommon.m
//  host
//
//  Created by midoks on 15/2/11.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import "NSCommon.h"


@implementation NSCommon

#pragma mark 获取上一级目录
+(NSString *)getDirName:(NSString *)dirname
{
    NSArray *i = [dirname componentsSeparatedByString:@"/"];
    NSMutableArray *ii = [[NSMutableArray alloc] initWithArray:i];
    [ii removeLastObject];
    NSString *r = [ii componentsJoinedByString:@"/"];
    return r;
}

#pragma mark 获取运行根目录
+ (NSString *)getRootDir
{
    char path[1024];
    unsigned size = 1024;
    
    _NSGetExecutablePath(path, &size);
    path[size] = '\0';
    
    NSString *str = [NSString stringWithFormat:@"%s", path];
    str = [self getDirName:str];
    str = [NSString stringWithFormat:@"%@", str];
    return str;
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
    NSString *bundleID = @"com.midoks.mdserver";
    NSURL * appAsUrl = [asPath.firstObject URLByAppendingPathComponent:bundleID];
    
    [self createDirIfNoExist:appAsUrl];
    return appAsUrl;
}


#pragma mark - Host文件操作 -
+(NSString *)getHostFileNeedContent{
    NSURL *dirUrl = [NSCommon appSupportDirURL];
    NSURL *pathplist = [dirUrl URLByAppendingPathComponent:@"server.plist"];
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
//    NSString *pathplist = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
    NSMutableDictionary *listContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[pathplist path]];
    
    for (NSMutableDictionary *k in listContent) {
        [list addObject:[listContent objectForKey:k]];
    }
    
    NSString *ret = @"";
    for (NSMutableDictionary *i in list) {
        if ([[i objectForKey:@"path"] isNotEqualTo:@""] && [[i objectForKey:@"hostname"] isNotEqualTo:@"localhost"]) {
            ret = [NSString stringWithFormat:@"\n%@\n127.0.0.1\t\t%@\t%@",
                   ret,
                   [i objectForKey:@"hostname"],
                   @"#MDserver Hosts Don`t Remove and Change"];
        }
    }
    
    NSString *content = [NSString stringWithContentsOfFile:@"/etc/hosts" encoding:NSUTF8StringEncoding error:nil];
    ret = [NSString stringWithFormat:@"%@\n%@", content, ret];
    return ret;
}

#pragma mark - 删除 -
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
    return content;
}

@end
