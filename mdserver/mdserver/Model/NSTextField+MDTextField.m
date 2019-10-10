//
//  NSTextField+MDTextField.m
//  mdserver
//
//  Created by midoks on 2019/10/10.
//  Copyright © 2019年 midoks.cachecha.com. All rights reserved.
//

#import "NSTextField+MDTextField.h"

@implementation NSTextField (MDTextField)

-(void)changeText:(void(^)(void)) callback
{
    
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
-(void)textDidChange:(NSNotification *)notification
{
    
//    self.text
    NSLog(@"xx tag : %@",self.stringValue);
}
#pragma clang diagnostic pop


@end
