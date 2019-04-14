//
//  HostNameController.m
//  mdserver
//
//  Created by midoks on 15/2/2.
//  Copyright (c) 2015年 midoks.cachecha.com. All rights reserved.
//

#import "HostNameController.h"
#import "HostNameModel.h"
#import "NSCommon.h"

@interface HostNameController()
@end

@implementation HostNameController

- (id)init
{
//    NSLog(@"HostNameController");
    
    if (self = [super init]) {
        [_tableView setGridColor:[NSColor blackColor]];
        [_tableView setRowSizeStyle:NSTableViewRowSizeStyleLarge];
        [_tableView setGridStyleMask:(NSTableViewSolidHorizontalGridLineMask | NSTableViewSolidVerticalGridLineMask)];
        [[_tableView cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [[_tableView cell] setTruncatesLastVisibleLine:YES];
        [_tableView setColumnAutoresizingStyle:NSTableViewSequentialColumnAutoresizingStyle];
        [_tableView setUsesAlternatingRowBackgroundColors:NO];
        [_tableView.headerView setHidden:YES];//使用隐藏的效果会出现表头的高度
        
        _tableView.delegate = self;
        _tableView.dataSource = self;
        //plist操作
        [self reloadListData];
        
        _phplist = [[NSMutableArray alloc] init];
        NSFileManager *fm = [NSFileManager  defaultManager];
        NSString *rootDir           = [NSCommon getRootDir];
        NSString *phpDir = [NSString stringWithFormat:@"%@bin/php", rootDir];
        NSArray *phpVlist = [fm contentsOfDirectoryAtPath:phpDir error:NULL];
        
        for (NSString *f in phpVlist) {
            
            NSString *path =[NSString stringWithFormat:@"%@/%@", phpDir,f];
            BOOL isDir;
            [fm fileExistsAtPath:path isDirectory:&isDir];
            if (!isDir){
                continue;
            }
            
            NSString *v = [f stringByReplacingOccurrencesOfString:@"php" withString:@""];
            [_phplist addObject:v];
        }
        
        [_phplist sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 intValue]>[obj2 intValue]){
                return YES;
            }
            return NO;
        }];
    }
    return  self;
}

-(void)awakeFromNib
{
    //默认路径为空
    //[_serverPath setURL:[NSURL URLWithString:@"file://"]];
    [NSCommon delayedRun:0.5 callback:^{
        static BOOL reload = YES;
        if (reload) {//默认选择
            if ([self->_list count] > 0) {
                [self->_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:0] byExtendingSelection:YES];
            }
            reload = NO;
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_list count];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    HostNameModel *hnm = [_list objectAtIndex:row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    [cell.textField setStringValue:[hnm valueForKey:tableColumn.identifier]];
    [cell.textField setEditable:NO];
    [cell.textField setDrawsBackground:NO];
    return cell;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (dropOperation == NSTableViewDropAbove) {
        return NSDragOperationNone;
    }
    return NSDragOperationMove;
}

#pragma mark 点击选择框
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [_serverPHPVer removeAllItems];
    for (NSString *i in _phplist) {
        [_serverPHPVer addItemWithTitle:i];
    }
    
    [_serverPHPVer setTarget:self];
    [_serverPHPVer setAction:@selector(handlePopBtn:)];
    
    NSInteger row = [_tableView selectedRow];
    if (row > -1) {
        NSMutableDictionary *serverinfo = [_list objectAtIndex:row];
        [_serverName setStringValue:[serverinfo objectForKey:@"hostname"]];
        [_serverPort setStringValue:[serverinfo objectForKey:@"port"]];
        [_serverPHPVer setStringValue:[serverinfo objectForKey:@"php"]];
        
        NSString *php = [serverinfo objectForKey:@"php"];
        NSInteger cphp = [_phplist indexOfObject:php];
        if (cphp > -1){
            [_serverPHPVer selectItemAtIndex:cphp];
        }
        
        if ([[serverinfo objectForKey:@"hostname"] isEqual:@"localhost"]) {
            _serverName.enabled = NO;
            _serverPort.enabled = NO;
            _serverPHPVer.enabled = NO;
        }else{
            _serverName.enabled = YES;
            _serverPort.enabled = YES;
            _serverPHPVer.enabled = YES;
        }
        
        NSString * path = [serverinfo objectForKey:@"path"];
        if ([path isEqual:@""]) {
            _emptyPath.hidden = NO;
            [_serverPath setURL:[NSURL URLWithString:@"file://"]];
        }else{
            NSString *urlstr = [NSString stringWithFormat:@"file://%@", path];
            [_serverPath setURL:[NSURL URLWithString:urlstr]];
            _emptyPath.hidden = YES;
        }
    }
}

#pragma mark - NSTextFieldDelegate -
#pragma mark - IBACTION -
#pragma mark 添加功能
-(IBAction)add:(id)sender
{
    NSString *hostname = [NSString stringWithFormat:@"host-%ld", [_list count]+1];
    NSString *port = _gPort.stringValue;
    NSString *php = _serverPHPVer.stringValue;
    
    [_serverName setStringValue:hostname];
    [_serverPort setStringValue:port];
//    [_serverPHPVer setStringValue:php];
    
    [_list addObject:[[HostNameModel alloc] setWithHost:hostname port:port path:@"" php:php]];
    
    [_tableView reloadData];
    [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:[_list count]-1] byExtendingSelection:YES];
}

#pragma mark 删除功能
-(IBAction)remove:(id)sender
{
    NSInteger row = [_tableView selectedRow];
    
    if (row!=-1) {
        
        NSMutableDictionary *serverinfo = [_list objectAtIndex:row];
        
        if ([[serverinfo objectForKey:@"hostname"] isEqual:@"localhost"]) {
            return;
        }
        
        if ([[serverinfo objectForKey:@"path"] isNotEqualTo:@""])
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"删除设置"];
            [alert setInformativeText:@"你是否确认删除有设置路径的配置"];
            [alert addButtonWithTitle:@"确定"];
            [alert addButtonWithTitle:@"取消"];
            [alert setAlertStyle:NSInformationalAlertStyle];
            NSModalResponse r = [alert runModal];
            
            if (r != 1000) {
                return;
            }
        }
        
        [_list removeObjectAtIndex:row];
        
        //保存配置
        [self save:sender];
        
        [_tableView reloadData];
        [_tableView deselectAll:sender];
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:[_list count] - 1] byExtendingSelection:YES];
        
    }else{
        NSLog(@"没有选择!!!");
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:[_list count] - 1] byExtendingSelection:YES];
    }
}

-(void)reloadListData
{
    _list = [[NSMutableArray alloc] init];
    NSString *str = [NSCommon getRootDir];
    NSString *pathplist = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
    NSMutableDictionary *listContent = [[NSMutableDictionary alloc] initWithContentsOfFile:pathplist];
    
    for (NSInteger i=0; i<[listContent count]; i++) {
        NSString *pos = [NSString stringWithFormat:@"%ld", i];
        NSMutableDictionary *t = [listContent objectForKey:pos];
        
        if ([[t objectForKey:@"hostname"] isEqual:@"localhost"])
        {
            NSString *urlstr = [NSString stringWithFormat:@"%@htdocs/www/", str];
            [[listContent objectForKey:pos] setObject:urlstr forKey:@"path"];
            [[listContent objectForKey:pos] setObject:@"55" forKey:@"php"];
        }
        
        if (![[listContent objectForKey:pos] objectForKey:@"php"]){
             [[listContent objectForKey:pos] setObject:@"55" forKey:@"php"];
        }
        
        [_list addObject:t];
    }
    [_tableView reloadData];
}

#pragma mark 恢复功能
-(IBAction)revert:(id)sender
{
    [self reloadListData];
    //默认选择
    if ([_list count] > 0) {
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:0] byExtendingSelection:YES];
    }
}

#pragma mark 保存功能
-(IBAction)save:(id)sender
{
    NSString *pathplist = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"plist"];
    NSMutableDictionary *dictplist  = [[NSMutableDictionary alloc] init];
    NSUInteger c = 0;
    //NSLog(@"_list:%@", _list);
    for (NSDictionary *i in _list)
    {
//        NSLog(@"i:%@", i);
        NSMutableDictionary *serverinfo = [[NSMutableDictionary alloc] init];
        [serverinfo setObject:[i objectForKey:@"hostname"] forKey:@"hostname"];
        [serverinfo setObject:[i objectForKey:@"port"] forKey:@"port"];
        [serverinfo setObject:[i objectForKey:@"path"] forKey:@"path"];
        [serverinfo setObject:[i objectForKey:@"php"] forKey:@"php"];
        [dictplist setObject:serverinfo forKey:[NSString stringWithFormat:@"%ld", c]];
        ++c;
    }
    
    NSMutableDictionary *listContent = [[NSMutableDictionary alloc] initWithContentsOfFile:pathplist];
    
    //判断是否改变
    BOOL isNotify = false;
    
    //数量上判断
    if ([listContent count] != [_list count]){
        isNotify = true;
    }
    
    NSString *hostname = @"";
    NSString *port = @"";
    NSString *path = @"";
    NSString *php = @"";
    
    //内容上判断
    if(!isNotify){
        
        for (id key in listContent){
            int key_num = [key intValue];
            
            id obj = [listContent objectForKey:key];
            
            hostname = [obj objectForKey:@"hostname"];
            port     = [obj objectForKey:@"port"];
            path     = [obj objectForKey:@"path"];
            php     = [obj objectForKey:@"php"];
            
            if([[[_list objectAtIndex:key_num] objectForKey:@"hostname"] isEqualToString:hostname] &&
               [[[_list objectAtIndex:key_num] objectForKey:@"port"] isEqualToString:port] &&
               [[[_list objectAtIndex:key_num] objectForKey:@"path"] isEqualToString:path] &&
                [[[_list objectAtIndex:key_num] objectForKey:@"php"] isEqualToString:php]){
            
            } else {
                isNotify = true;
            }
        }
    }

    [dictplist writeToFile:pathplist atomically:YES];
    
    //改变后,重新启动,发送通知
    if (isNotify){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@""];
        [alert setInformativeText:@"你是否重新启动服务?"];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setAlertStyle:NSInformationalAlertStyle];
        NSModalResponse r = [alert runModal];
        
        if (1001 == r) {
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadSVC" object:nil];
    }
}

#pragma mark 选择文件
-(IBAction)selectedDIr:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt: @"choose"];
    [panel setCanChooseDirectories:YES];    //可以打开目录
    [panel setCanChooseFiles:NO];           //不能选择文件
    
    [panel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
        [self->_serverPath setURL:[panel URL]];
        [self->_emptyPath setHidden:YES];
        
        NSInteger row = [self->_tableView selectedRow];
        if (row > -1) {
            NSString *path = [[[panel URL] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            [[self->_list objectAtIndex:row] setObject:path forKey:@"path"];
            
            [self save:sender];
        }
    }];
}

- (IBAction)openDir:(id)sender
{
    NSURL *pathstring = [_serverPath URL];
    NSString *dir = [[pathstring absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    
    if (![dir isEqual:@""]) {
        [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:dir, nil]] waitUntilExit];
    }
}

#pragma mark NSPathControlDelegate
- (IBAction)openCellDir:(id)sender
{
    NSURL *pathstring = [[_serverPath clickedPathComponentCell] URL];
    NSString *dir = [[pathstring absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObjects:dir, nil]] waitUntilExit];
}

-(IBAction)changeServerName:(id)sender
{
    NSInteger row = [_tableView selectedRow];
    if (row != -1) {
        [[_list objectAtIndex:row] setObject:[_serverName stringValue] forKey:@"hostname"];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row] byExtendingSelection:YES];
        
        if ([[[_list objectAtIndex:row] objectForKey:@"path"] isNotEqualTo:@""]) {
            [self save:sender];
        }
    }
}

-(IBAction)changeServerPort:(id)sender
{
    NSInteger row = [_tableView selectedRow];
    if (row != -1) {
        
        NSInteger port = [_serverPort integerValue];
        //默认0-1023是系统默认的端口,需要root权限才能开启。
        if (port < 80) {
            port = 80;
        } else if (port > 65534){
            port = 65534;
        }
        
        NSString *portstr = [NSString stringWithFormat:@"%ld", port];
        [[_list objectAtIndex:row] setObject:portstr forKey:@"port"];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row] byExtendingSelection:YES];
        
        if ([[[_list objectAtIndex:row] objectForKey:@"path"] isNotEqualTo:@""]) {
            [self save:sender];
        }
    }
}

-(void)handlePopBtn:(NSPopUpButton *)popBtn
{
    popBtn.title = popBtn.selectedItem.title;
    NSInteger row = [_tableView selectedRow];
    
    if (row != -1) {
        [[_list objectAtIndex:row] setObject:popBtn.title forKey:@"php"];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row] byExtendingSelection:YES];

        if ([[[_list objectAtIndex:row] objectForKey:@"path"] isNotEqualTo:@""]) {
            [self save:popBtn];
        }
    }
}

- (IBAction)goWebSite:(id)sender {
    NSInteger row = [_tableView selectedRow];
    if(row>-1){
        NSMutableDictionary *rowdata = [_list objectAtIndex:row];
        NSString *gourl = [NSString stringWithFormat:@"http://%@:%@", [rowdata objectForKey:@"hostname"], [rowdata objectForKey:@"port"]];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:gourl]];
        //NSLog(@"%ld", row);
        //[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:8888/"]];
    }
}

- (IBAction)goWebInfo:(id)sender {
    NSInteger row = [_tableView selectedRow];
    NSString *title = [pStartTitle stringValue];
    
    if((row>-1) && ([title isEqual:@"stop"])){
        NSMutableDictionary *rowdata = [_list objectAtIndex:row];
        NSString *hostname = [rowdata objectForKey:@"hostname"];
        NSString *port = [rowdata objectForKey:@"port"];
        NSString *path = [rowdata objectForKey:@"path"];
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSString *gourl = [NSString stringWithFormat:@"http://%@:%@", hostname, port];
        
        long r = random();
        gourl  = [NSString stringWithFormat:@"%@/tmp_%ld.php", gourl, r];
        path = [NSString stringWithFormat:@"%@tmp_%ld.php", path, r];
 
        [NSCommon makePhpInfo:path];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:gourl]];
        [NSCommon delayedRun:5.0 callback:^{
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:path error:nil];
        }];
    }
}

@end
