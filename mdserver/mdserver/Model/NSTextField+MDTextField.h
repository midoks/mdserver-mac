//
//  NSTextField+MDTextField.h
//  mdserver
//
//  Created by midoks on 2019/10/10.
//  Copyright © 2019年 midoks.cachecha.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextField (MDTextField)

-(void)changeText:(void(^)(void)) callback;

@end
