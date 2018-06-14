
#import "GSRequest.h"

//#define GSMEMORYLOG

@interface GSRequest ()

@end

@implementation GSRequest

+ (instancetype)request {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Set default value for GSRequest instance
    _requestType = kGSRequestNormal;
    _httpMethod = kGSHTTPMethodPOST;
    _requestSerializerType = kGSRequestSerializerRAW;
    _responseSerializerType = kGSResponseSerializerJSON;
    _timeoutInterval = 60.0;
    
    _useGeneralServer = YES;
    _useGeneralHeaders = YES;
    _useGeneralParameters = YES;
    
    _retryCount = 0;
    
#ifdef GSMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (void)cleanCallbackBlocks {
    _successBlock = nil;
    _failureBlock = nil;
    _finishedBlock = nil;
    _progressBlock = nil;
}

- (NSMutableArray<GSUploadFormData *> *)uploadFormDatas {
    if (!_uploadFormDatas) {
        _uploadFormDatas = [NSMutableArray array];
    }
    return _uploadFormDatas;
}

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData {
    GSUploadFormData *formData = [GSUploadFormData formDataWithName:name fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    GSUploadFormData *formData = [GSUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    GSUploadFormData *formData = [GSUploadFormData formDataWithName:name fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    GSUploadFormData *formData = [GSUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

#ifdef GSMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - GSBatchRequest

@interface GSBatchRequest () {
    dispatch_semaphore_t _lock;
    NSUInteger _finishedCount;
    BOOL _failed;
}

@property (nonatomic, copy) GSBCSuccessBlock batchSuccessBlock;
@property (nonatomic, copy) GSBCFailureBlock batchFailureBlock;
@property (nonatomic, copy) GSBCFinishedBlock batchFinishedBlock;

@end

@implementation GSBatchRequest

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _failed = NO;
    _finishedCount = 0;
    _lock = dispatch_semaphore_create(1);

    _requestArray = [NSMutableArray array];
    _responseArray = [NSMutableArray array];

#ifdef GSMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (BOOL)onFinishedOneRequest:(GSRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
    GSLock();
    NSUInteger index = [_requestArray indexOfObject:request];
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:index withObject:responseObject];
    } else {
        _failed = YES;
        if (error) {
            [_responseArray replaceObjectAtIndex:index withObject:error];
        }
    }
    
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        if (!_failed) {
            GS_SAFE_BLOCK(_batchSuccessBlock, _responseArray);
            GS_SAFE_BLOCK(_batchFinishedBlock, _responseArray, nil);
        } else {
            GS_SAFE_BLOCK(_batchFailureBlock, _responseArray);
            GS_SAFE_BLOCK(_batchFinishedBlock, nil, _responseArray);
        }
        [self cleanCallbackBlocks];
        isFinished = YES;
    }
    GSUnlock();
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _batchSuccessBlock = nil;
    _batchFailureBlock = nil;
    _batchFinishedBlock = nil;
}

#ifdef GSMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - GSChainRequest

@interface GSChainRequest () {
    NSUInteger _chainIndex;
}

@property (nonatomic, strong, readwrite) GSRequest *runningRequest;

@property (nonatomic, strong) NSMutableArray<GSBCNextBlock> *nextBlockArray;
@property (nonatomic, strong) NSMutableArray *responseArray;

@property (nonatomic, copy) GSBCSuccessBlock chainSuccessBlock;
@property (nonatomic, copy) GSBCFailureBlock chainFailureBlock;
@property (nonatomic, copy) GSBCFinishedBlock chainFinishedBlock;

@end

@implementation GSChainRequest : NSObject

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _chainIndex = 0;
    _responseArray = [NSMutableArray array];
    _nextBlockArray = [NSMutableArray array];
    
#ifdef GSMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (GSChainRequest *)onFirst:(GSRequestConfigBlock)firstBlock {
    NSAssert(firstBlock != nil, @"The first block for chain requests can't be nil.");
    NSAssert(_nextBlockArray.count == 0, @"The `-onFirst:` method must called befault `-onNext:` method");
    _runningRequest = [GSRequest request];
    firstBlock(_runningRequest);
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (GSChainRequest *)onNext:(GSBCNextBlock)nextBlock {
    NSAssert(nextBlock != nil, @"The next block for chain requests can't be nil.");
    [_nextBlockArray addObject:nextBlock];
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (BOOL)onFinishedOneRequest:(GSRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:_chainIndex withObject:responseObject];
        if (_chainIndex < _nextBlockArray.count) {
            _runningRequest = [GSRequest request];
            GSBCNextBlock nextBlock = _nextBlockArray[_chainIndex];
            BOOL isSent = YES;
            nextBlock(_runningRequest, responseObject, &isSent);
            if (!isSent) {
                GS_SAFE_BLOCK(_chainFailureBlock, _responseArray);
                GS_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
                [self cleanCallbackBlocks];
                isFinished = YES;
            }
        } else {
            GS_SAFE_BLOCK(_chainSuccessBlock, _responseArray);
            GS_SAFE_BLOCK(_chainFinishedBlock, _responseArray, nil);
            [self cleanCallbackBlocks];
            isFinished = YES;
        }
    } else {
        if (error) {
            [_responseArray replaceObjectAtIndex:_chainIndex withObject:error];
        }
        GS_SAFE_BLOCK(_chainFailureBlock, _responseArray);
        GS_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
        [self cleanCallbackBlocks];
        isFinished = YES;
    }
    _chainIndex++;
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _runningRequest = nil;
    _chainSuccessBlock = nil;
    _chainFailureBlock = nil;
    _chainFinishedBlock = nil;
    [_nextBlockArray removeAllObjects];
}

#ifdef GSMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - GSUploadFormData

@implementation GSUploadFormData

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData {
    GSUploadFormData *formData = [[GSUploadFormData alloc] init];
    formData.name = name;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    GSUploadFormData *formData = [[GSUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    GSUploadFormData *formData = [[GSUploadFormData alloc] init];
    formData.name = name;
    formData.fileURL = fileURL;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    GSUploadFormData *formData = [[GSUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileURL = fileURL;
    return formData;
}

@end
