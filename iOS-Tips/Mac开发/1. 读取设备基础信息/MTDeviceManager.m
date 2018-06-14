//
//  MTDeviceManager.m
//  GSnitch
//
//  Created by lcd on 2018/6/8.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "MTDeviceManager.h"
#import "MobileDevice.h"

@interface MTDeviceManager()

@property (nonatomic, copy) MTDeviceManagerStatusDidChangeHandler statusChangeHandler;
@end

static MTDeviceManager *manager;
struct am_device *device;
struct am_device_notification *notification;
static BOOL connected;

void notificationCallBack(struct am_device_notification_callback_info *info, int cookie) {
    if (info -> msg == ADNCI_MSG_CONNECTED) {
        NSLog(@"Device connected");
        connected = YES;
        device = info -> dev;
        AMDeviceConnect(device);
        AMDeviceIsPaired(device);
        AMDeviceValidatePairing(device);
        AMDeviceStartSession(device);
        manager.statusChangeHandler(MTDeviceManagrStatusTypeConnected);
    } else if (info -> msg == ADNCI_MSG_DISCONNECTED) {
        connected = NO;
        NSLog(@"Device disconnected");
        manager.statusChangeHandler(MTDeviceManagrStatusTypeDisconnected);
        
    } else {
        NSLog(@"Recieved device notification: %d", info -> msg);
        connected = NO;
        manager.statusChangeHandler(MTDeviceManagrStatusUnknown);
    }
}


@implementation MTDeviceManager


- (instancetype)init {
    self = [super init];
    if (self) {
        manager = self;
        AMDeviceNotificationSubscribe(notificationCallBack, 0, 0, 0, &notification);
    }
    return self;
}

-(void)listenStatus:(MTDeviceManagerStatusDidChangeHandler)handler {
    if (handler) {
        self.statusChangeHandler = handler;
    }
}


- (NSString *)deviceInfoValue:(NSString *)value {
    return (__bridge NSString *)AMDeviceCopyValue(device, 0, (__bridge CFStringRef)value);
}

-(NSString *)deviceName {
    return [self deviceInfoValue:@"DeviceName"];
}

-(NSString *)deviceModel {
    return [self deviceInfoValue:@"ProductType"];
}

-(NSString *)version {
    return [NSString stringWithFormat:@"iOS %@",[self deviceInfoValue:@"ProductVersion"]];
}

-(NSString *)serialNumber {
    return [self deviceInfoValue:@"SerialNumber"];
}

-(NSString *)uniqueDeviceID {
    return [self deviceInfoValue:@"UniqueDeviceID"];
}

-(NSString *)phoneNumber {
    return [self deviceInfoValue:@"PhoneNumber"];
}

- (NSString *)local {
    return [self deviceInfoValue:@"Locale"];
}
-(BOOL)isConnected {
    return connected;
}
@end
