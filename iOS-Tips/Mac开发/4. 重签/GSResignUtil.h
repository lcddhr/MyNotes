//
//  GSResignUtil.h
//  GSnitch
//
//  Created by lcd on 2018/6/11.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface GSResignConfig : NSObject
@property (nonatomic, copy) NSString *ipaFilePath;
@property (nonatomic, copy) NSString *certificateName;
@property (nonatomic, copy) NSString *profilePath;
@property (nonatomic, copy) NSString *exportPath;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *bundleVersion;
@property (nonatomic, copy) NSString *resignScriptPath;

@property (nonatomic, copy) NSString *resignScriptExportFileName;
@end

typedef void(^GSResignUtilCompletionHandler)(NSString *stantOutput, NSString *exportPath,BOOL success);

@interface GSResignUtil : NSObject

+ (NSArray *)detectLackResignCommand;


+ (void)resignUsingConfig:(void(^)(GSResignConfig *config))configBlock
        completionHandler:(GSResignUtilCompletionHandler)completionHandler;

@end
