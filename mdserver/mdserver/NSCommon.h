//
//  NSCommon.h
//  mdserver
//
//  Created by midoks on 15/1/26.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <mach-o/dyld.h>

@interface NSCommon : NSObject

#pragma mark - 弹出提示 -
+(void)alert:(NSString *)content;
+(void)alert:(NSString *)content delayedClose:(float)t;

#pragma mark 延迟回调
+(void)delayedRun:(float)t callback:(void(^)(void)) callback;

#pragma mark 只执行一次方法
+(void)runOneTime:(NSString *)sign run:(void(^)(void))run;

#pragma mark 判断文件是否存在
+(BOOL)fileIsExists:(NSString *)absPathFile;

#pragma mark 打开文件
+(void)openFile:(NSString *)file;

#pragma mark 获取进程执行结构
+(void)getProcessReturn:(NSString *)pathsh;

#pragma mark 获取运行根目录
+ (NSString *)getRootDir;

#pragma mark 获取app目录
+(NSString *)getAppDir;


#pragma mark HostCofig
+(BOOL)saveNginxConfig;
+(BOOL)setRemoveAllConfig;
+(BOOL)setConfigWithServerName:(NSString *)serverName port:(NSString *)port path:(NSString *)path;


+(NSString *)getHostFileNeedContent;
+(NSString *)setHostFileNotNeedContent:(NSString *)content;

#pragma mark LogFlush
+(BOOL)setFlushLog:(NSString *)path;

#pragma mark 全局设置
+(BOOL)setCommonConfig:(NSString *)name value:(id)value;
+(id)getCommonConfig:(NSString *)name;


#pragma mark 创建info文件
+(BOOL)makePhpInfo:(NSString *)path;


@end
