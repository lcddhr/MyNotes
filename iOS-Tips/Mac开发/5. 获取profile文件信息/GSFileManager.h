//
//  MTFilePathManager.h
//  MTProfileManager
//
//  Created by lcd on 2018/4/19.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSFileManager : NSObject

+ (instancetype)sharedInstance;


- (NSString *)profileDirectory;


- (void)createProjectDirectory:(NSString *)projectName;
- (void)createProfileDirectory;
- (void)createLogDirectory;
- (void)createQuickLook;

- (BOOL)deleteFile:(NSString *)filePath option:(BOOL)totle;
- (BOOL)moveFileToTrashPath:(NSString *)path error:(NSError **)error;

- (void)moveFileAtPath:(NSString *)path toPath:(NSString *)toPath;

- (void)clear;



- (NSString *)cacheDirectory;

- (void)writeLog:(NSString *)log;

/**
 解压
 
 @param filePath 压缩包路径
 @param dstPath 解压路径
 @param completeBlock 结果
 */
- (void)unzip:(NSString *)filePath toPath:(NSString *)dstPath complete:(void(^)(BOOL result))completeBlock;


/**
 压缩
 
 @param srcPath 待压缩的路径
 @param dstFilePath 压缩包保存路径
 @param completeBlock 结果
 */
- (void)zip:(NSString *)srcPath toPath:(NSString *)dstFilePath complete:(void(^)(BOOL result))completeBlock;

@end
