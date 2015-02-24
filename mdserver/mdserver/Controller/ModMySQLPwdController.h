//
//  ModMySQLPwdController.h
//  mdserver
//
//  Created by midoks on 15/2/13.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ModMySQLPwdController : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSSecureTextField *mysqlPwd;
    IBOutlet NSSecureTextField *mysqlRePwd;

}


- (IBAction)exitMySQLPwd:(id)sender;
- (IBAction)updateMySQLPwd:(id)sender;
@end
