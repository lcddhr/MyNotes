//
//  GSCommandTaskUtil.h
//  GSnitch
//
//  Created by meitu on 2018/5/2.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^GSCommandTaskCompletionHandler)(NSString *standardErrorString, NSString *standardOutput, NSError *error);

@interface GSCommandTaskUtil : NSObject

+ (NSString *)executeCommand:(NSString *)command launchPath:(NSString *)launchPath;
+ (NSString *)runTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;
+ (void)executeCommand:(NSString *)command
                  launchPath:(NSString *)launchPath
           completionHandler:(GSCommandTaskCompletionHandler)completionHandler;

+ (void)installDmgAtPath:(NSURL *)filePath;
@end
