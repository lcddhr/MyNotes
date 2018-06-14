//
//  GSRunloopUtil.h
//  GSnitch
//
//  Created by lcd on 2018/6/7.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSRunloopUtil : NSObject

@property (nonatomic) BOOL isSuspend;

- (void)run:(void (^)(void))block;
- (void)stop:(void (^)(void))complete;
@end
