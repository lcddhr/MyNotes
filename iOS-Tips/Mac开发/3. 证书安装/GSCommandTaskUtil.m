//
//  GSCommandTaskUtil.m
//  GSnitch
//
//  Created by meitu on 2018/5/2.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSCommandTaskUtil.h"

@implementation GSCommandTaskUtil

+ (void)executeCommand:(NSString *)command
                  launchPath:(NSString *)launchPath
           completionHandler:(GSCommandTaskCompletionHandler)completionHandler {
    NSTask *task = [[NSTask alloc] init];
    if (launchPath) {
        [task setLaunchPath:launchPath];
    } else {
        [task setLaunchPath:@"/bin/sh"];
    }
    
    NSArray *arguments = @[@"-c", [NSString stringWithFormat:@"%@", command]];
    [task setArguments:arguments];
    
    NSPipe *standardOutputPipe = [NSPipe pipe];
    NSPipe *standardErrorPipe = [NSPipe pipe];
    [task setStandardOutput:standardOutputPipe];
    [task setStandardError:standardErrorPipe];
    
    NSError *error = nil;
    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&error];
    } else {
        // Fallback on earlier versions
        [task launch];
    }
    
    if(error) {
        if (completionHandler) {
            completionHandler(nil,nil, error);
        }
        return;
    }
    
    NSFileHandle *outputfile = [standardOutputPipe fileHandleForReading];
    NSFileHandle *errorFile = [standardErrorPipe fileHandleForReading];
    
    NSString *errorString = [[NSString alloc] initWithData:[errorFile readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSString *outputString = [[NSString alloc] initWithData:[outputfile readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    if (completionHandler) {
        completionHandler(errorString, outputString,nil);
    }
}
+ (NSString *)executeCommand:(NSString *)command launchPath:(NSString *)launchPath {
    NSTask *task = [[NSTask alloc] init];
    if (launchPath) {
        [task setLaunchPath:launchPath];
    } else {
        [task setLaunchPath:@"/bin/sh"];
    }
    
    NSArray *arguments = @[@"-c", [NSString stringWithFormat:@"%@", command]];
    [task setArguments:arguments];
    
    NSPipe *standardOutputPipe = [NSPipe pipe];
    NSPipe *standardErrorPipe = [NSPipe pipe];
    [task setStandardOutput:standardOutputPipe];
    [task setStandardError:standardErrorPipe];
    
    NSFileHandle *file = [standardOutputPipe fileHandleForReading];
    NSFileHandle *errorFile = [standardErrorPipe fileHandleForReading];
    NSError *error = nil;
    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&error];
    } else {
        // Fallback on earlier versions
        [task launch];
    }
    
    if(error) {
        return nil;
    }
    
    
    NSString *outputErrorFile = [[NSString alloc] initWithData:[errorFile readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSLog(@"%@",outputErrorFile);
    
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

+ (NSString *)runTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments {
    
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = path;
    if (arguments.count > 0) {
        task.arguments = arguments;
    }
    [task setStandardOutput:pipe];
    [task launch];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    return [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
}

+ (void)installDmgAtPath:(NSURL *)filePath {
    NSString *path = [filePath path];
    NSString *command = [NSString stringWithFormat:@"open %@",path];
    [GSCommandTaskUtil executeCommand:command launchPath:nil];
}
@end
