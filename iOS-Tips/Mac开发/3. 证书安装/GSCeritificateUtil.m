//
//  GSCeritificateUtil.m
//  GSnitch
//
//  Created by meitu on 2018/5/9.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSCeritificateUtil.h"
#import "GSCommandTaskUtil.h"
#import "GSLogUtil.h"

@implementation GSCeritificateUtil

// 找到证书的SHA1
+ (NSString *)findCertificateSHA1:(NSURL *)fileURL {
    
    NSString *command = [NSString stringWithFormat:@"shasum '%@'",fileURL.path];
    NSString *result = [GSCommandTaskUtil executeCommand:command launchPath:nil];
    if (result.length > 0) {
        NSArray *temp = [result componentsSeparatedByString:@" "];
        if (temp.count > 2) {
            NSString *sha1 = temp.firstObject;
            return [sha1 uppercaseString];
        }
    }
    return nil;
}

+ (BOOL)verifyCertificate:(NSURL *)fileURL {
    
    // 1. 找到证书对应的sha1
    NSString *sha1 = [self findCertificateSHA1:fileURL];
    
    // 2. 判断是否包含 sha1
    NSString *command = @"security find-identity -v -p codesigning";
    NSString *result = [GSCommandTaskUtil executeCommand:command launchPath:nil];
    if ([result containsString:sha1]) {
        return YES;
    }
    return NO;
}

+ (void)importP12AtPath:(NSURL *)p12FileURL completionHandler:(GSCeritificateImportHandler)handler {
    [self importCertificateAtPath:p12FileURL completionHandler:handler];
}

+ (void)importCertificateAtPath:(NSURL *)certificateFileURL completionHandler:(GSCeritificateImportHandler)handler {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:certificateFileURL.path]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:certificateFileURL.path error:nil];
        if ([fileAttributes fileSize] == 0) {
            NSError *error = [NSError errorWithDomain:@"" code:-10001 userInfo:@{@"filesizeError" : @"file下载失败, 容量为0"}];
            handler(@"", NO,error);
            return;
        }
    } else {
        NSLog(@"文件不存在 %@",certificateFileURL);
        NSString *message = [NSString stringWithFormat:@"%@ 不存在",certificateFileURL.path];
        NSError *error = [NSError errorWithDomain:@"" code:-10002 userInfo:@{@"fillerror" : message}];
        handler(@"", NO,error);
        return;
    }
    NSString *path = certificateFileURL.path;
    NSString *password = @"''";
    NSString *loginKeychainPath = @"~/Library/Keychains/login.keychain"; // 默认
    NSString *codsign = @"/usr/bin/codesign";
    NSString *security = @"/usr/bin/security";
    NSString *command = [NSString stringWithFormat:@"security import '%@' -P %@ -k %@ -T %@ -T %@",path,password,loginKeychainPath,codsign,security];
    NSLog(@"执行的命令是 %@",command);
    [GSCommandTaskUtil executeCommand:command launchPath:nil completionHandler:^(NSString *standardErrorString, NSString *standardOutput, NSError *error) {
        BOOL isSuccess = [standardOutput containsString:@"certificate imported"];
        if (handler) {
            handler(standardErrorString, isSuccess,error);
        }
    }];
}

+ (BOOL)importProfileAtPath:(NSURL *)profileURL {
    NSString *path = [profileURL path];
    NSString *profileDirectory =  [NSString stringWithFormat:@"%@/Library/MobileDevice/Provisioning Profiles/",NSHomeDirectory()];
    NSString *toPath = [NSString stringWithFormat:@"%@%@",profileDirectory, [path lastPathComponent]];
    
    // profile是覆盖安装
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:toPath error:&error];
        if (error) {
            NSLog(@"importProfile removeItemAtPath error :%@", error);
        }
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:toPath error:&error];
    
    if (error) {
        NSLog(@"importProfile copyItemAtPath error :%@", error);
        return NO;
    }
    return YES;
}

+ (void)fetchCertificates:(void(^)(NSArray *certificates))completionHandler {
    NSTask *certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:@"/usr/bin/security"];
    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
    NSPipe *pipe = [NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    [certTask launch];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 检查 KeyChain 中是否有证书，然后把证书保存到 self.certificatesArray
        NSString *securityResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        if (securityResult == nil || securityResult.length < 1) return;
        NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
        NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
        for (int i = 0; i <= [rawResult count] - 2; i += 2) {
            if (!(rawResult.count - 1 < i + 1)) {
                // 有效的
                [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
            }
        }
        __block NSMutableArray *certificatesArray = [NSMutableArray arrayWithArray:tempGetCertsResult];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (certificatesArray.count > 0) {
                if (completionHandler != nil)
                    completionHandler(certificatesArray.copy);
            } else {
                completionHandler(nil);
            }
        });
    });
}


@end
