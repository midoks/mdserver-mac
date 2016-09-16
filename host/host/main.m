//
//  main.m
//  host
//
//  Created by midoks on 15/2/11.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSCommon.h"



int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        //NSLog(@"Hello, World!");
        
        //#1 写入需要的内容
        NSString *content = [NSCommon getHostFileNeedContent];
        return [content writeToFile:@"/etc/hosts" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        //#2 删除不需要的内容
//        NSString *content = [NSString stringWithContentsOfFile:@"/etc/hosts" encoding:NSUTF8StringEncoding error:nil];
//        content = [NSCommon setHostFileNotNeedContent:content];
//        return [content writeToFile:@"/etc/hosts" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return 0;
}
