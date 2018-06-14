//
//  MTProfileManager.h
//  MTProfileManager
//
//  Created by lcd on 2018/4/19.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSProfileManager : NSObject

+ (instancetype)sharedInstance;


- (NSArray *)loadProfileData;


/**
 解析profile文件里面DeveloperCertificates字段信息

 @param data 原始数据
 @return 处理之后的结果
 */
- (NSDictionary *)parseCertificate:(NSData *)data;


/**
 profile文件里面的数据, 格式与plist文件一样

 @param path 数据地址
 @return 处理后的结果
 */
- (NSDictionary *)readPlistAtPath:(NSString *)path;
@end
