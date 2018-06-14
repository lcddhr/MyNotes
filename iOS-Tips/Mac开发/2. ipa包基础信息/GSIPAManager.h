//
//  GSIPAManager.h
//  GSnitch
//
//  Created by lcd on 2018/6/14.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSIPAModel :NSObject

@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *version;

@end

typedef void(^GSIPAManagerCompletionHandler)(GSIPAModel *model, BOOL success, NSError *error);
@interface GSIPAManager : NSObject

+(instancetype)sharedInstance;

- (void)parseIPAFileAtPath:(NSString *)path completionHandler:(GSIPAManagerCompletionHandler)completionHandler;
@end
