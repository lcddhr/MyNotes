//
//  GSProfileManager.m
//  GSProfileManager
//
//  Created by lcd on 2018/4/19.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSProfileManager.h"
#import "GSFileManager.h"

@interface GSProfileManager()

@end

@implementation GSProfileManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static GSProfileManager *profileManager = nil;
    dispatch_once(&onceToken, ^{
        profileManager = [[GSProfileManager alloc] init];
    });
    return profileManager;
}

- (NSArray *)loadProfileData {

    // 解析profileData数据
    NSMutableArray *profileData = [NSMutableArray array];
    NSString *profileDirectory = [[GSFileManager sharedInstance] profileDirectory];
    NSArray *matchFileExtensions = @[@"mobileprovision",@"MOBILEPROVISION",@"provisionprofile",@"PROVISIONPROFILE"];
    NSArray *profileNames = [[[NSFileManager defaultManager] subpathsAtPath:profileDirectory] pathsMatchingExtensions:matchFileExtensions];
    
    if (!profileNames || !profileNames.count) {
        return nil;
    }
    
    [profileNames enumerateObjectsUsingBlock:^(NSString   * _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [NSString stringWithFormat:@"%@%@", profileDirectory, fileName];
        NSMutableDictionary *fileDic = [[self readPlistAtPath:filePath] mutableCopy];
        fileDic[@"filePath"] = filePath;
        [profileData addObject:fileDic];
    }];
    return profileData;
}


- (NSDictionary *)readPlistAtPath:(NSString *)path {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *beginString = @"<?xml version";
        NSString *endString    = @"</plist>";
        
        NSData *rawData = [NSData dataWithContentsOfFile:path];
        NSData *beginData = [NSData dataWithBytes:[beginString UTF8String] length:beginString.length];
        NSData *endData = [NSData dataWithBytes:[endString UTF8String] length:endString.length];
        NSRange fullRange = NSMakeRange(0, rawData.length);
        
        NSRange beginRange = [rawData rangeOfData:beginData options:0 range:fullRange];
        NSRange endRange = [rawData rangeOfData:endData options:0 range:fullRange];
        
        NSRange plistRange = NSMakeRange(beginRange.location, endRange.location + endRange.length - beginRange.location);
        NSData *plistData = [rawData subdataWithRange:plistRange];
        
        NSError *error = nil;
        id obj = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:&error];
        if (error) {
            NSLog(@"plist 文件解析错误");
            return nil;
        }
        
        if (![obj isKindOfClass:[NSDictionary class]]) {
            NSLog(@"解析出错, 不是字典");
            return nil;
        }
        
        return obj;
    }
    return nil;
}

- (NSDictionary *)parseCertificate:(NSData *)data {
    static NSString *const devCertSummaryKey = @"summary";
    static NSString *const devCertInvalidityDateKey = @"invalidity";
    
    NSMutableDictionary *detailsDict;
    SecCertificateRef certificateRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    if (certificateRef) {
        CFStringRef summaryRef = SecCertificateCopySubjectSummary(certificateRef);
        NSString *summary = (NSString *)CFBridgingRelease(summaryRef);
        if (summary) {
            detailsDict = [NSMutableDictionary dictionaryWithObject:summary forKey:devCertSummaryKey];
            
            CFErrorRef error;
            CFDictionaryRef valuesDict = SecCertificateCopyValues(certificateRef, (__bridge CFArrayRef)@[(__bridge id)kSecOIDInvalidityDate], &error);
            if (valuesDict) {
                CFDictionaryRef invalidityDateDictionaryRef = CFDictionaryGetValue(valuesDict, kSecOIDInvalidityDate);
                if (invalidityDateDictionaryRef) {
                    CFTypeRef invalidityRef = CFDictionaryGetValue(invalidityDateDictionaryRef, kSecPropertyKeyValue);
                    CFRetain(invalidityRef);
                    
                    // NOTE: the invalidity date type of kSecPropertyTypeDate is documented as a CFStringRef in the "Certificate, Key, and Trust Services Reference".
                    // In reality, it's a __NSTaggedDate (presumably a tagged pointer representing an NSDate.) But to sure, we'll check:
                    id invalidity = CFBridgingRelease(invalidityRef);
                    if (invalidity) {
                        if ([invalidity isKindOfClass:[NSDate class]]) {
                            // use the date directly
                            [detailsDict setObject:invalidity forKey:devCertInvalidityDateKey];
                        }
                        else {
                            // parse the date from a string
                            NSString *string = [invalidity description];
                            NSDateFormatter *invalidityDateFormatter = [NSDateFormatter new];
                            [invalidityDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
                            NSDate *invalidityDate = [invalidityDateFormatter dateFromString:string];
                            if (invalidityDate) {
                                [detailsDict setObject:invalidityDate forKey:devCertInvalidityDateKey];
                            }
                        }
                    }
                    else {
//                        NSLog(@"No invalidity date in '%@' certificate, dictionary = %@", summary, invalidityDateDictionaryRef);
                        [detailsDict setObject:@"No invalidity date" forKey:devCertInvalidityDateKey];
                    }
                }
                else {
//                    NSLog(@"No invalidity values in '%@' certificate, dictionary = %@", summary, valuesDict);
                    [detailsDict setObject:@"No invalidity values" forKey:devCertInvalidityDateKey];
                    
                }
                
                CFRelease(valuesDict);
            }
            else {
//                NSLog(@"Could not get values in '%@' certificate, error = %@", summary, error);
            }
            
        }
        else {
//            NSLog(@"Could not get summary from certificate");
        }
        
        CFRelease(certificateRef);
    }
    return detailsDict;
    
}
@end
