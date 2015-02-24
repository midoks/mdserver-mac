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
    str = [self getDirName:str];
    str = [self getDirName:str];
    str = [self getDirName:str];
    str = [NSString stringWithFormat:@"%@/mdserver/bin", str];
    return str;
}


@end
