//
//  GSResignUtil.m
//  GSnitch
//
//  Created by lcd on 2018/6/11.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSResignUtil.h"
#import "GSRunloopUtil.h"
#import "GSLogUtil.h"

#define GS_RESIGN_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })

@implementation GSResignConfig
@end

@implementation GSResignUtil

+ (NSArray *)detectLackResignCommand {
    NSMutableArray *commands = [[NSMutableArray alloc] init];
    NSArray *needDetectCommand = @[
                                    @"/usr/bin/zip",
                                    @"/usr/bin/unzip",
                                    @"/usr/bin/codesign"
                                   ];
    [needDetectCommand enumerateObjectsUsingBlock:^(NSString *commandPath, NSUInteger idx, BOOL * _Nonnull stop) {

        if (![[NSFileManager defaultManager] fileExistsAtPath:commandPath]) {
            [commands addObject:commandPath];
        }
    }];
    return commands;
}

+ (void)resignUsingConfig:(void(^)(GSResignConfig *config))configBlock
        completionHandler:(GSResignUtilCompletionHandler)completionHandler {
    GSResignConfig *config = [[GSResignConfig alloc] init];
    GS_RESIGN_SAFE_BLOCK(configBlock,config);
    
    NSTask *certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:config.resignScriptPath];
    [certTask setCurrentDirectoryPath:[config.resignScriptPath stringByDeletingLastPathComponent]]; //脚本的运行不能在默认的根目录
    NSMutableArray *arguements = [NSMutableArray array];
    [arguements addObject:config.ipaFilePath];
    [arguements addObject:config.certificateName];
    [arguements addObject:@"-v"];
    [arguements addObject:@"-p"];
    [arguements addObject:config.profilePath];
    
    if (config.bundleID.length > 0) {
        [arguements addObject:@"-b"];
        [arguements addObject:config.bundleID];
    }
    
    if (config.bundleVersion.length > 0) {
        [arguements addObject:@"--version-number"];
        [arguements addObject:config.bundleVersion];
    }
    [arguements addObject:config.exportPath];
    [certTask setArguments:arguements];
    NSPipe *pipe = [NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    [certTask launch];
    
    GSRunloopUtil *runloop = [GSRunloopUtil new];
    [runloop run:^{
        if ([certTask isRunning] == 0) {
            [runloop stop:^{
                NSMutableString *s = [[NSMutableString alloc] init];
                int terminationStatus = certTask.terminationStatus;
                [s appendString:[NSString stringWithFormat:@"terminationStatus %d \n",terminationStatus]];
                NSString *test = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
                [s appendString:[NSString stringWithFormat:@"%@\n",test]];
                if (terminationStatus == 0) {
                    NSString *securityResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
                    NSString *resignIPAPath = [NSString stringWithFormat:@"%@/%@",config.exportPath,config.resignScriptExportFileName];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:resignIPAPath]) {
                        [s appendString:@"签名成功"];
                        if (completionHandler) {
                            completionHandler(securityResult, resignIPAPath,YES);
                        }
                    } else {
                        [s appendString:[NSString stringWithFormat:@"文件不存在 %@",resignIPAPath]];
                        if (completionHandler) {
                            completionHandler(securityResult,nil,NO);
                        }
                    }
                    
                    
                } else {
                    
                    if (completionHandler) {
                        completionHandler(nil,nil,NO);
                    }
                }
                
                [GSLogUtil sendLog:s];
            }];
        }
    }];
}
@end
