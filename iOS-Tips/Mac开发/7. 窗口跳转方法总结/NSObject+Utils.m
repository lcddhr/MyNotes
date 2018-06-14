//
//  NSObject+Utils.m
//  GSnitch
//
//  Created by meitu on 2018/5/4.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "NSObject+Utils.h"

@implementation NSObject (Utils)

- (void)gs_showInFinderAtPath:(NSString *)filePath {
    
    if (!filePath || !filePath.length) {
        NSLog(@"打开失败, filePath 错误");
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"文件不存在");
        return;
    }
    [[NSWorkspace sharedWorkspace] selectFile:filePath inFileViewerRootedAtPath:@""];
}

- (void)gs_showSavePanelOnWindow:(NSWindow *)window
               allowedFileTypes :(NSArray *)fileTypes
                        fileName:(NSString *)fileName
                   directoryPath:(NSString *)directoryPath
               completionHandler:(void(^)(BOOL success, NSSavePanel *savePannel))completionHandler {
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = fileTypes;
    savePanel.nameFieldStringValue = fileName;
    savePanel.directoryURL = [NSURL fileURLWithPath:directoryPath];
    [savePanel beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
        
        if (completionHandler){
            if (result == NSModalResponseOK){
                completionHandler(YES, savePanel);
            } else {
                completionHandler(NO, savePanel);
            }
        }
    }];
}

- (void)gs_showOpenPannelAllowedFileTypes:(NSArray *)fileTypes
                completionHandler:(void(^)(BOOL success, NSOpenPanel *openPannel))completionHandler {
    
    NSOpenPanel *openFilePannel = [NSOpenPanel openPanel];
    [openFilePannel setCanChooseFiles:YES];
    [openFilePannel setCanChooseDirectories:NO];
    [openFilePannel setAllowsMultipleSelection:NO];
    [openFilePannel setAllowsOtherFileTypes:NO];
    [openFilePannel setAllowedFileTypes:fileTypes];
    
    [openFilePannel beginWithCompletionHandler:^(NSModalResponse result) {
        
        if (completionHandler){
            if (result == NSModalResponseOK){
                completionHandler(YES, openFilePannel);
            } else {
                completionHandler(NO, openFilePannel);
            }
        }
    }];
}
@end
