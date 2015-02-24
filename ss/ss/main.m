//
//  main.m
//  ss
//
//  Created by midoks on 15/2/12.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSCommon.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        //NSLog(@"Hello, World!");
        
        NSString *root = [NSCommon getRootDir];
        
        //#1.启动
        NSString *start = [NSString stringWithFormat:@"%@/stop.sh", root];
        //NSLog(@"%@", start);
        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", start, nil]] waitUntilExit];
        
        
        //#2.停止
//        NSString *stop = [NSString stringWithFormat:@"%@/stop.sh", root];
//        [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", stop, nil]] waitUntilExit];
    }
    return 0;
}
