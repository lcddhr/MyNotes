//
//  MTDeviceManager.h
//  GSnitch
//
//  Created by lcd on 2018/6/8.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTDeviceManagrStatusType) {
    MTDeviceManagrStatusTypeConnected,
    MTDeviceManagrStatusTypeDisconnected,
    MTDeviceManagrStatusUnknown,
};

typedef void(^MTDeviceManagerStatusDidChangeHandler)(MTDeviceManagrStatusType type);
@interface MTDeviceManager : NSObject

@property (nonatomic, copy, readonly) NSString *deviceName;
@property (nonatomic, copy, readonly) NSString *deviceModel;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *serialNumber;
@property (nonatomic, copy, readonly) NSString *uniqueDeviceID;
@property (nonatomic, copy, readonly) NSString *phoneNumber;
@property (nonatomic, copy, readonly) NSString *local;

@property (nonatomic, assign, readonly) BOOL isConnected;


- (void)listenStatus:(MTDeviceManagerStatusDidChangeHandler)handler;

@end
