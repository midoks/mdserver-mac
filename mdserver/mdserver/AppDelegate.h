//
//  AppDelegate.h
//  mdserver
//
//  Created by midoks on 15/1/22.
//  Copyright (c) 2015年 midoks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSCommon.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>{

    NSStatusItem        *statusBarItem;
    IBOutlet NSMenu     *statusBarItemMenu;
    IBOutlet NSMenuItem *phpVer;
    IBOutlet NSMenuItem *cmd;
    NSMutableArray <NSMenuItem *> *phpList;

//基本属性
    IBOutlet NSProgressIndicator *pProgress;
    IBOutlet NSButton *pNginxStatus;
    IBOutlet NSButton *pPHPStatus;
    
    IBOutlet NSButton *pStart;
    IBOutlet NSTextField *pStartTitle;
    IBOutlet NSButton *pReStart;
    

//权限测试
    AuthorizationRef        _authRef;
}

#pragma mark - 帮助中心 -
- (IBAction)showAbout:(id)sender;
- (IBAction)showMain:(id)sender;
- (IBAction)showDonateAlipay:(id)sender;
- (IBAction)showWeibo:(id)sender;


#pragma mark  - 启动或暂停 -
- (IBAction)start:(id)sender;
- (IBAction)goWeb:(id)sender;


#pragma mark - General通用设置 -

#pragma mark - redis和mongodb相关 -
- (IBAction)redisStart:(id)sender;
- (IBAction)goRedisWeb:(id)sender;
- (IBAction)mongoStart:(id)sender;
- (IBAction)goMongoWeb:(id)sender;
- (IBAction)MySQLStart:(id)sender;
- (IBAction)goMySQL:(id)sender;
//- (IBAction)goNeo4j:(id)sender;

@end

