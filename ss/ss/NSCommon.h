//
//  NSCommon.h
//  host
//
//  Created by midoks on 15/2/11.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <mach-o/dyld.h>

@interface NSCommon : NSObject


#pragma mark 获取运行根目录
+ (NSString *)getRootDir;
@end
