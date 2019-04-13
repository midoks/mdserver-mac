//
//  NSTextField+Copypast.h
//  mdserver
//
//  Created by midoks on 2019/4/13.
//  Copyright © 2019年 midoks.cachecha.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextField (Copypast)
- (BOOL)performKeyEquivalent:(NSEvent *)event;
@end
