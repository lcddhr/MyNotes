//
//  MTFilePathManager.m
//  MTProfileManager
//
//  Created by lcd on 2018/4/19.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSFileManager.h"
#import <Cocoa/Cocoa.h>
#import "GSRunloopUtil.h"

@interface GSFileManager ()

@property (nonatomic, copy) NSString *logPath;
@end

@implementation GSFileManager

+ (instancetype)sharedInstance {
    static GSFileManager *filePathManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        filePathManager = [[GSFileManager alloc] init];
    });
    return filePathManager;
}

- (NSString *)profileDirectory {
    
    NSString *profileDirectory =  [NSString stringWithFormat:@"%@/Library/MobileDevice/Provisioning Profiles/",NSHomeDirectory()];
    return profileDirectory;
}

- (NSString *)logDirectory {
    NSString *dicPath = [NSString stringWithFormat:@"%@/Library/Logs/dogeX",NSHomeDirectory()];
    return dicPath;
}

- (void)createProfileDirectory {
    NSString *profileDirectory = [self profileDirectory];
    [self createDirectory:profileDirectory];
}

- (void)createLogDirectory {
    NSString *dicPath = [self logDirectory];
    [self createDirectory:dicPath];
}

- (void)createDirectory:(NSString *)path {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
}

- (BOOL)deleteFile:(NSString *)filePath option:(BOOL)totle {
    
    NSError *error;
    BOOL result = NO;
    if (totle) {
        result = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    } else {
        result = [self moveFileToTrashPath:filePath error:&error];
    }
    
    if (error) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[error localizedDescription]];
        [alert beginSheetModalForWindow:NSApp.keyWindow completionHandler:^(NSModalResponse returnCode) {
        }];
    }
    return result;
}

- (BOOL)moveFileToTrashPath:(NSString *)path error:(NSError **)error {
    NSParameterAssert(path != nil);
    NSString *trashPath = [NSString stringWithFormat:@"%@/.Trash", NSHomeDirectory()];
    NSString *proposedPath = [trashPath stringByAppendingPathComponent:[path lastPathComponent]];
    return [[NSFileManager defaultManager] moveItemAtPath:path toPath:[self uniqueFileNameWithPath:proposedPath] error:error];
}

- (void)moveFileAtPath:(NSString *)path toPath:(NSString *)toPath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] moveItemAtPath:path toPath:toPath error:nil];
    }
}

- (NSString *)uniqueFileNameWithPath:(NSString *)aPath {
    NSParameterAssert(aPath != nil);
    
    NSString *baseName = [aPath stringByDeletingPathExtension];
    NSString *suffix = [aPath pathExtension];
    NSUInteger n = 2;
    NSString *fname = aPath;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:fname]) {
        if ([suffix length] == 0)
            fname = [baseName stringByAppendingString:[NSString stringWithFormat:@" %zi", n++]];
        else
            fname = [baseName stringByAppendingString:[NSString stringWithFormat:@" %zi.%@", n++, suffix]];
        
        if (n <= 0)
            return nil;
    }
    
    return fname;
}

- (void)createProjectDirectory:(NSString *)projectName {
    if (!projectName) return;
    
    NSString *dir = [self cacheDirectory];
    NSString *projectDir = [NSString stringWithFormat:@"%@/%@",dir,projectName];
    [self createDirectory:projectDir];
}

- (void)clear {
    NSString *dir = [self cacheDirectory];
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    NSString *fileName = @"";
    
    while (([direnum nextObject])) {
        fileName = [NSString stringWithFormat:@"%@/%@",dir,[direnum nextObject]];
        BOOL needDeleteFile =   [fileName hasSuffix:@".mobileprovision"] ||
                                [fileName hasSuffix:@".p12"] ||
                                [fileName hasSuffix:@".cer"] ||
                                [fileName hasSuffix:@".dmg"];
        if (needDeleteFile) {
            [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
        }
    }
}

- (void)createQuickLook {
    
    // 创建QuickLook目录
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library"];
    NSString *projectDir = [NSString stringWithFormat:@"%@/QuickLook",dir];
    if (![[NSFileManager defaultManager] fileExistsAtPath:projectDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:projectDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ProvisionQL" ofType:@"qlgenerator"];
    NSString *toPath = [NSString stringWithFormat:@"%@/%@",projectDir,[path lastPathComponent]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:path toPath:toPath error:&error];
    }
}

- (NSString *)cacheDirectory {
    
    return [NSHomeDirectory() stringByAppendingString:@"/.GSnitch"];
}

- (void)writeLog:(NSString *)log {
    if (!_logPath) {
        _logPath = [NSString stringWithFormat:@"%@/dogeX_%lld.log",[self logDirectory],(long long)[[NSDate date] timeIntervalSince1970]];
        
    }
    NSString *localString = [[NSString alloc] initWithContentsOfFile:_logPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *saveLog = [[NSMutableString alloc] init];
    if (localString && localString.length > 0) {
        saveLog = [localString mutableCopy];
    }
    [saveLog appendString:[NSString stringWithFormat:@"%@\n",log]];
    [saveLog writeToFile:_logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - Unzip
- (void)unzip:(NSString *)filePath toPath:(NSString *)dstPath complete:(void (^)(BOOL))completeBlock {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) completeBlock(NO);
    
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", filePath, @"-d", dstPath, nil]];
    [unzipTask launch];
    
    GSRunloopUtil *runloop = [GSRunloopUtil new];
    [runloop run:^{
        if ([unzipTask isRunning] == 0) {
            [runloop stop:^{
                int terminationStatus = unzipTask.terminationStatus;
                if (terminationStatus == 0) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:dstPath]) {
                        completeBlock(YES);
                    }
                } else {
                    completeBlock(NO);
                }
            }];
        }
    }];
}

#pragma mark - zip
- (void)zip:(NSString *)srcPath toPath:(NSString *)dstFilePath complete:(void (^)(BOOL))completeBlock {
    NSTask *zipTask = [[NSTask alloc] init];
    [zipTask setLaunchPath:@"/usr/bin/zip"];
    [zipTask setCurrentDirectoryPath:srcPath];
    [zipTask setArguments:@[@"-qry", dstFilePath, @"."]];
    [zipTask launch];
    
    GSRunloopUtil *runloop = [GSRunloopUtil new];
    [runloop run:^{
        if ([zipTask isRunning] == 0) {
            [runloop stop:^{
                int terminationStatus = zipTask.terminationStatus;
                if (terminationStatus == 0) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:dstFilePath]) {
                        completeBlock(YES);
                    } else {
                        completeBlock(NO);
                    }
                } else {
                    completeBlock(NO);
                }
            }];
        }
    }];
}
@end
