//
//  NSObject+Utils.h
//  GSnitch
//
//  Created by meitu on 2018/5/4.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface NSObject (Utils)

// 跳转到filePath
- (void)gs_showInFinderAtPath:(NSString *)filePath;

// 保存窗口
- (void)gs_showSavePanelOnWindow:(NSWindow *)window
               allowedFileTypes :(NSArray *)fileTypes
                        fileName:(NSString *)fileName
                       directoryPath:(NSString *)directoryPath
               completionHandler:(void(^)(BOOL success, NSSavePanel *savePannel))completionHandler;

// 选择窗口
- (void)gs_showOpenPannelAllowedFileTypes:(NSArray *)fileTypes
                completionHandler:(void(^)(BOOL success, NSOpenPanel *openPannel))completionHandler;
@end
