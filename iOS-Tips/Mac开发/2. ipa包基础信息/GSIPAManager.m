//
//  GSIPAManager.m
//  GSnitch
//
//  Created by lcd on 2018/6/14.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSIPAManager.h"
#import "GSFileManager.h"

@implementation GSIPAModel

-(instancetype)init {
    self = [super init];
    if (self) {
        
        self.bundleID = @"";
        self.version = @"";
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"bundle = %@, version = %@ \n",self.bundleID, self.version];
}
@end

@interface GSIPAManager ()

@property (nonatomic, copy) NSString *unzipPath;
@property (nonatomic, copy) NSString *infoPlistPath;
@property (nonatomic, copy) NSString *profilePath;
@property (nonatomic, copy) NSDictionary *infoPlistData;

@end

@implementation GSIPAManager

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static GSIPAManager *ipaManager;
    dispatch_once(&onceToken, ^{
        ipaManager = [[GSIPAManager alloc] init];
    });
    return ipaManager;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.unzipPath = [NSTemporaryDirectory() stringByAppendingString:@"com.meitu.ipainfo"];
    }
    return self;
}

- (void)parseIPAFileAtPath:(NSString *)path completionHandler:(GSIPAManagerCompletionHandler)completionHandler {
    
    [[NSFileManager defaultManager] removeItemAtPath:self.unzipPath error:nil];
    __weak typeof(self)weakSelf = self;
    [[GSFileManager sharedInstance] unzip:path toPath:self.unzipPath complete:^(BOOL result) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (result) {
            BOOL hasPayload =  [[NSFileManager defaultManager] fileExistsAtPath:[strongSelf.unzipPath stringByAppendingPathComponent:@"Payload"]];
            if (!hasPayload) {
                NSLog(@"未能找到Payload目录");
                NSError *error = [NSError errorWithDomain:@"com.meitu.ipamanager" code:-10001 userInfo:@{@"PayloadError" : @"未能找到Payload目录"}];
                if (completionHandler) {
                    completionHandler(nil, NO, error);
                }
                return;
            }
            // 找到plist文件
            [self findFiles];
            
            // 解析plist文件数据
            [self parseFiles];
            
            if (self.infoPlistData) {
               NSString *version =  self.infoPlistData[@"CFBundleShortVersionString"];
                NSString *bundleID = self.infoPlistData[@"CFBundleIdentifier"];
                GSIPAModel *ipaModel = [[GSIPAModel alloc] init];
                ipaModel.version = version;
                ipaModel.bundleID = bundleID;
                if (completionHandler) {
                    completionHandler(ipaModel, YES, nil);
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"com.meitu.ipamanager" code:-10001 userInfo:@{@"unzipError" : @"解压失败..."}];
            if (completionHandler) {
                completionHandler(nil, NO, error);
            }
        }
    }];
}

- (void)findFiles {
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.unzipPath stringByAppendingPathComponent:@"Payload"] error:nil];
    [dirContents enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"app"]) {
            self.infoPlistPath = [NSString stringWithFormat:@"%@/Payload/%@/Info.plist",self.unzipPath,filePath];
            // 找到profile文件
            self.profilePath = [NSString stringWithFormat:@"%@/Payload/%@/embedded.mobileprovision",self.unzipPath, filePath];
        }
    }];
}

- (void)parseFiles {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.infoPlistPath]) {
        NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:self.infoPlistPath];
        self.infoPlistData = dic;
    } else {
        NSLog(@"未能找到 %@ 文件",[NSString stringWithFormat:@"未能找到 %@ 文件", self.infoPlistPath]);
    }
    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:self.profilePath]) {
//        NSMutableDictionary *profileDic = [[[GSProfileManager sharedInstance] readPlistAtPath:self.profilePath] mutableCopy];
//        NSData *certData = [[profileDic objectForKey:@"DeveloperCertificates"] firstObject];
//        NSDictionary *temp = [[GSProfileManager sharedInstance] parseCertificate:certData];
//        [profileDic setObject:temp forKey:@"DeveloperCertificates"];
//        self.certResultTextView.string = [profileDic description];
//    } else {
//        self.plistResultTextView.string = [NSString stringWithFormat:@"未能找到 %@ 文件", self.profilePath];
//    }
}
@end
