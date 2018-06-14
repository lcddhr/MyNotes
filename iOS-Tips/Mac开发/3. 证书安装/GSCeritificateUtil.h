//
//  GSCeritificateUtil.h
//  GSnitch
//
//  Created by meitu on 2018/5/9.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^GSCeritificateImportHandler)(NSString *standardErrorString, BOOL isSuccess, NSError *error);
@interface GSCeritificateUtil : NSObject


/**
 判断证书是否安装并且有效

 @param fileURL 证书路径
 @return 布尔值是否有效
 */
+ (BOOL)verifyCertificate:(NSURL *)fileURL;


/**
 证书导入

 @param certificateFileURL 证书所在路径
 @param handler 导入完成的回调
 */
+ (void)importCertificateAtPath:(NSURL *)certificateFileURL completionHandler:(GSCeritificateImportHandler)handler;



/**
 导入p12文件

 @param p12FileURL p12文件路径
 @param handler 导入完成的回调
 */
+ (void)importP12AtPath:(NSURL *)p12FileURL completionHandler:(GSCeritificateImportHandler)handler;

/**
 profile导入

 @param profileURL profile文件路径
 @return 导入完成是否成功
 */
+ (BOOL)importProfileAtPath:(NSURL *)profileURL;


/**
 获取本地证书名称

 @param completionHandler 成功回调
 */
+ (void)fetchCertificates:(void(^)(NSArray *certificates))completionHandler;
@end
