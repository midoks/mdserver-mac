//
//  HostNameModel.h
//  mdserver
//
//  Created by midoks on 15/2/2.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HostNameModel : NSObject

@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *php;



#pragma mark 初始化值
- (id)initWithHost:(NSString *)host port:(NSString *)port path:(NSString *)path php:(NSString *)php;
-(NSMutableDictionary *)setWithHost:(NSString *)host port:(NSString *)port path:(NSString *)path php:(NSString *)php;
@end
