
#import "GSCenter.h"
#import "GSRequest.h"
#import "GSEngine.h"

@interface GSCenter () {
    dispatch_semaphore_t _lock;
}

@property (nonatomic, assign) NSUInteger autoIncrement;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *runningBatchAndChainPool;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, id> *generalParameters;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

@property (nonatomic, copy) GSCenterResponseProcessBlock responseProcessHandler;
@property (nonatomic, copy) GSCenterRequestProcessBlock requestProcessHandler;
@property (nonatomic, copy) GSCenterErrorProcessBlock errorProcessHandler;

@end

@implementation GSCenter

+ (instancetype)center {
    return [[[self class] alloc] init];
}

+ (instancetype)defaultCenter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self center];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _autoIncrement = 0;
    _lock = dispatch_semaphore_create(1);
    _engine = [GSEngine sharedEngine];
    return self;
}

#pragma mark - Public Instance Methods for GSCenter

- (void)setupConfig:(void(^)(GSConfig *config))block {
    GSConfig *config = [[GSConfig alloc] init];
    config.consoleLog = NO;
    GS_SAFE_BLOCK(block, config);
    
    if (config.generalServer) {
        self.generalServer = config.generalServer;
    }
    if (config.generalParameters.count > 0) {
        [self.generalParameters addEntriesFromDictionary:config.generalParameters];
    }
    if (config.generalHeaders.count > 0) {
        [self.generalHeaders addEntriesFromDictionary:config.generalHeaders];
    }
    if (config.callbackQueue != NULL) {
        self.callbackQueue = config.callbackQueue;
    }
    if (config.generalUserInfo) {
        self.generalUserInfo = config.generalUserInfo;
    }
    if (config.engine) {
        self.engine = config.engine;
    }
    self.consoleLog = config.consoleLog;
}

- (void)setRequestProcessBlock:(GSCenterRequestProcessBlock)block {
    self.requestProcessHandler = block;
}

- (void)setResponseProcessBlock:(GSCenterResponseProcessBlock)block {
    self.responseProcessHandler = block;
}

- (void)setErrorProcessBlock:(GSCenterErrorProcessBlock)block {
    self.errorProcessHandler = block;
}

- (void)setGeneralHeaderValue:(NSString *)value forField:(NSString *)field {
    [self.generalHeaders setValue:value forKey:field];
}

- (void)setGeneralParameterValue:(id)value forKey:(NSString *)key {
    [self.generalParameters setValue:value forKey:key];
}

#pragma mark -

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onProgress:(nullable GSProgressBlock)progressBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onProgress:(nullable GSProgressBlock)progressBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    GSRequest *request = [GSRequest request];
    GS_SAFE_BLOCK(configBlock, request);
    
    [self gs_processRequest:request onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
    [self gs_sendRequest:request];
    
    return request.identifier;
}

- (NSString *)sendBatchRequest:(GSBatchRequestConfigBlock)configBlock
                     onSuccess:(nullable GSBCSuccessBlock)successBlock
                     onFailure:(nullable GSBCFailureBlock)failureBlock
                    onFinished:(nullable GSBCFinishedBlock)finishedBlock {
    GSBatchRequest *batchRequest = [[GSBatchRequest alloc] init];
    GS_SAFE_BLOCK(configBlock, batchRequest);
    
    if (batchRequest.requestArray.count > 0) {
        if (successBlock) {
            [batchRequest setValue:successBlock forKey:@"_batchSuccessBlock"];
        }
        if (failureBlock) {
            [batchRequest setValue:failureBlock forKey:@"_batchFailureBlock"];
        }
        if (finishedBlock) {
            [batchRequest setValue:finishedBlock forKey:@"_batchFinishedBlock"];
        }
        
        [batchRequest.responseArray removeAllObjects];
        for (GSRequest *request in batchRequest.requestArray) {
            [batchRequest.responseArray addObject:[NSNull null]];
            __weak __typeof(self)weakSelf = self;
            [self gs_processRequest:request
                         onProgress:nil
                          onSuccess:nil
                          onFailure:nil
                         onFinished:^(id responseObject, NSError *error) {
                             if ([batchRequest onFinishedOneRequest:request response:responseObject error:error]) {
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 dispatch_semaphore_wait(strongSelf->_lock, DISPATCH_TIME_FOREVER);
                                 [strongSelf.runningBatchAndChainPool removeObjectForKey:batchRequest.identifier];
                                 dispatch_semaphore_signal(strongSelf->_lock);
                             }
                         }];
            [self gs_sendRequest:request];
        }
        
        NSString *identifier = [self gs_identifierForBatchAndChainRequest];
        [batchRequest setValue:identifier forKey:@"_identifier"];
        GSLock();
        [self.runningBatchAndChainPool setValue:batchRequest forKey:identifier];
        GSUnlock();
        
        return identifier;
    } else {
        return nil;
    }
}

- (NSString *)sendChainRequest:(GSChainRequestConfigBlock)configBlock
                     onSuccess:(nullable GSBCSuccessBlock)successBlock
                     onFailure:(nullable GSBCFailureBlock)failureBlock
                    onFinished:(nullable GSBCFinishedBlock)finishedBlock {
    GSChainRequest *chainRequest = [[GSChainRequest alloc] init];
    GS_SAFE_BLOCK(configBlock, chainRequest);
    
    if (chainRequest.runningRequest) {
        if (successBlock) {
            [chainRequest setValue:successBlock forKey:@"_chainSuccessBlock"];
        }
        if (failureBlock) {
            [chainRequest setValue:failureBlock forKey:@"_chainFailureBlock"];
        }
        if (finishedBlock) {
            [chainRequest setValue:finishedBlock forKey:@"_chainFinishedBlock"];
        }
        
        [self gs_sendChainRequest:chainRequest];
        
        NSString *identifier = [self gs_identifierForBatchAndChainRequest];
        [chainRequest setValue:identifier forKey:@"_identifier"];
        GSLock();
        [self.runningBatchAndChainPool setValue:chainRequest forKey:identifier];
        GSUnlock();
        
        return identifier;
    } else {
        return nil;
    }
}

#pragma mark -

- (void)cancelRequest:(NSString *)identifier {
    [self cancelRequest:identifier onCancel:nil];
}

- (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable GSCancelBlock)cancelBlock {
    id request = nil;
    if ([identifier hasPrefix:@"BC"]) {
        GSLock();
        request = [self.runningBatchAndChainPool objectForKey:identifier];
        [self.runningBatchAndChainPool removeObjectForKey:identifier];
        GSUnlock();
        if ([request isKindOfClass:[GSBatchRequest class]]) {
            GSBatchRequest *batchRequest = request;
            if (batchRequest.requestArray.count > 0) {
                for (GSRequest *rq in batchRequest.requestArray) {
                    if (rq.identifier.length > 0) {
                        [self.engine cancelRequestByIdentifier:rq.identifier];
                    }
                }
            }
        } else if ([request isKindOfClass:[GSChainRequest class]]) {
            GSChainRequest *chainRequest = request;
            if (chainRequest.runningRequest && chainRequest.runningRequest.identifier.length > 0) {
                [self.engine cancelRequestByIdentifier:chainRequest.runningRequest.identifier];
            }
        }
    } else if (identifier.length > 0) {
        request = [self.engine cancelRequestByIdentifier:identifier];
    }
    GS_SAFE_BLOCK(cancelBlock, request);
}

- (id)getRequest:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    } else if ([identifier hasPrefix:@"BC"]) {
        GSLock();
        id request = [self.runningBatchAndChainPool objectForKey:identifier];
        GSUnlock();
        return request;
    } else {
        return [self.engine getRequestByIdentifier:identifier];
    }
}

- (BOOL)isNetworkReachable {
    return self.engine.reachabilityStatus != 0;
}

- (GSNetworkConnectionType)networkConnectionType {
    return self.engine.reachabilityStatus;
}

#pragma mark - Public Class Methods for GSCenter

+ (void)setupConfig:(void(^)(GSConfig *config))block {
    [[GSCenter defaultCenter] setupConfig:block];
}

+ (void)setRequestProcessBlock:(GSCenterRequestProcessBlock)block {
    [[GSCenter defaultCenter] setRequestProcessBlock:block];
}

+ (void)setResponseProcessBlock:(GSCenterResponseProcessBlock)block {
    [[GSCenter defaultCenter] setResponseProcessBlock:block];
}

+ (void)setErrorProcessBlock:(GSCenterErrorProcessBlock)block {
    [[GSCenter defaultCenter] setErrorProcessBlock:block];
}

+ (void)setGeneralHeaderValue:(NSString *)value forField:(NSString *)field {
    [[GSCenter defaultCenter].generalHeaders setValue:value forKey:field];
}

+ (void)setGeneralParameterValue:(id)value forKey:(NSString *)key {
    [[GSCenter defaultCenter].generalParameters setValue:value forKey:key];
}

#pragma mark -

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onProgress:(nullable GSProgressBlock)progressBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(GSRequestConfigBlock)configBlock
               onProgress:(nullable GSProgressBlock)progressBlock
                onSuccess:(nullable GSSuccessBlock)successBlock
                onFailure:(nullable GSFailureBlock)failureBlock
               onFinished:(nullable GSFinishedBlock)finishedBlock {
    return [[GSCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendBatchRequest:(GSBatchRequestConfigBlock)configBlock
                     onSuccess:(nullable GSBCSuccessBlock)successBlock
                     onFailure:(nullable GSBCFailureBlock)failureBlock
                    onFinished:(nullable GSBCFinishedBlock)finishedBlock {
    return [[GSCenter defaultCenter] sendBatchRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendChainRequest:(GSChainRequestConfigBlock)configBlock
                     onSuccess:(nullable GSBCSuccessBlock)successBlock
                     onFailure:(nullable GSBCFailureBlock)failureBlock
                    onFinished:(nullable GSBCFinishedBlock)finishedBlock {
    return [[GSCenter defaultCenter] sendChainRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

#pragma mark -

+ (void)cancelRequest:(NSString *)identifier {
    [[GSCenter defaultCenter] cancelRequest:identifier onCancel:nil];
}

+ (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable GSCancelBlock)cancelBlock {
    [[GSCenter defaultCenter] cancelRequest:identifier onCancel:cancelBlock];
}

+ (nullable id)getRequest:(NSString *)identifier {
    return [[GSCenter defaultCenter] getRequest:identifier];
}

+ (BOOL)isNetworkReachable {
    return [[GSCenter defaultCenter] isNetworkReachable];
}

+ (GSNetworkConnectionType)networkConnectionType {
    return [[GSCenter defaultCenter] networkConnectionType];
}

#pragma mark -

+ (void)addSSLPinningURL:(NSString *)url {
    [[GSCenter defaultCenter].engine addSSLPinningURL:url];
}

+ (void)addSSLPinningCert:(NSData *)cert {
    [[GSCenter defaultCenter].engine addSSLPinningCert:cert];
}

+ (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password {
    [[GSCenter defaultCenter].engine addTwowayAuthenticationPKCS12:p12 keyPassword:password];
}

#pragma mark - Private Methods for GSCenter

- (void)gs_sendChainRequest:(GSChainRequest *)chainRequest {
    if (chainRequest.runningRequest != nil) {
        __weak __typeof(self)weakSelf = self;
        [self gs_processRequest:chainRequest.runningRequest
                     onProgress:nil
                      onSuccess:nil
                      onFailure:nil
                     onFinished:^(id responseObject, NSError *error) {
                         __strong __typeof(weakSelf)strongSelf = weakSelf;
                         if ([chainRequest onFinishedOneRequest:chainRequest.runningRequest response:responseObject error:error]) {
                             dispatch_semaphore_wait(strongSelf->_lock, DISPATCH_TIME_FOREVER);
                             [strongSelf.runningBatchAndChainPool removeObjectForKey:chainRequest.identifier];
                             dispatch_semaphore_signal(strongSelf->_lock);
                         } else {
                             if (chainRequest.runningRequest != nil) {
                                 [strongSelf gs_sendChainRequest:chainRequest];
                             }
                         }
                     }];
        
        [self gs_sendRequest:chainRequest.runningRequest];
    }
}

- (void)gs_processRequest:(GSRequest *)request
               onProgress:(GSProgressBlock)progressBlock
                onSuccess:(GSSuccessBlock)successBlock
                onFailure:(GSFailureBlock)failureBlock
               onFinished:(GSFinishedBlock)finishedBlock {
    
    // set callback blocks for the request object.
    if (successBlock) {
        [request setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [request setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (finishedBlock) {
        [request setValue:finishedBlock forKey:@"_finishedBlock"];
    }
    if (progressBlock && request.requestType != kGSRequestNormal) {
        [request setValue:progressBlock forKey:@"_progressBlock"];
    }
    
    // add general user info to the request object.
    if (!request.userInfo && self.generalUserInfo) {
        request.userInfo = self.generalUserInfo;
    }
    
    // add general parameters to the request object.
    if (request.useGeneralParameters && self.generalParameters.count > 0) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters addEntriesFromDictionary:self.generalParameters];
        if (request.parameters.count > 0) {
            [parameters addEntriesFromDictionary:request.parameters];
        }
        request.parameters = parameters;
    }
    
    // add general headers to the request object.
    if (request.useGeneralHeaders && self.generalHeaders.count > 0) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:self.generalHeaders];
        if (request.headers) {
            [headers addEntriesFromDictionary:request.headers];
        }
        request.headers = headers;
    }
    
    // process url for the request object.
    if (request.url.length == 0) {
        if (request.server.length == 0 && request.useGeneralServer && self.generalServer.length > 0) {
            request.server = self.generalServer;
        }
        if (request.api.length > 0) {
            NSURL *baseURL = [NSURL URLWithString:request.server];
            // ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected.
            if ([[baseURL path] length] > 0 && ![[baseURL absoluteString] hasSuffix:@"/"]) {
                baseURL = [baseURL URLByAppendingPathComponent:@""];
            }
            request.url = [[NSURL URLWithString:request.api relativeToURL:baseURL] absoluteString];
        } else {
            request.url = request.server;
        }
    }
    
    GS_SAFE_BLOCK(self.requestProcessHandler, request);
    NSAssert(request.url.length > 0, @"The request url can't be null.");
}

- (void)gs_sendRequest:(GSRequest *)request {
    
    if (self.consoleLog) {
        if (request.requestType == kGSRequestDownload) {
            NSLog(@"\n============ [GSRequest Info] ============\nrequest download url: %@\nrequest save path: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.downloadSavePath, request.headers, request.parameters);
        } else {
            NSLog(@"\n============ [GSRequest Info] ============\nrequest url: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.headers, request.parameters);
        }
    }
    
    // send the request through GSEngine.
    [self.engine sendRequest:request completionHandler:^(id responseObject, NSError *error) {
        // the completionHandler will be execured in a private concurrent dispatch queue.
        if (error) {
            [self gs_failureWithError:error forRequest:request];
        } else {
            [self gs_successWithResponse:responseObject forRequest:request];
        }
    }];
}

- (void)gs_successWithResponse:(id)responseObject forRequest:(GSRequest *)request {
    
    NSError *processError = nil;
    // custom processing the response data.
    id newResponseObject = GS_SAFE_BLOCK(self.responseProcessHandler, request, responseObject, &processError);
    if (newResponseObject) {
        responseObject = newResponseObject;
    }
    if (processError) {
        [self gs_failureWithError:processError forRequest:request];
        return;
    }
    
    if (self.consoleLog) {
        if (request.requestType == kGSRequestDownload) {
            NSLog(@"\n============ [GSResponse Data] ===========\nrequest download url: %@\nresponse data: %@\n==========================================\n", request.url, responseObject);
        } else {
            if (request.responseSerializerType == kGSResponseSerializerRAW) {
                NSLog(@"\n============ [GSResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            } else {
                NSLog(@"\n============ [GSResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, responseObject);
            }
        }
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf gs_execureSuccessBlockWithResponse:responseObject forRequest:request];
        });
    } else {
        // execure success block on a private concurrent dispatch queue.
        [self gs_execureSuccessBlockWithResponse:responseObject forRequest:request];
    }
}

- (void)gs_execureSuccessBlockWithResponse:(id)responseObject forRequest:(GSRequest *)request {
    GS_SAFE_BLOCK(request.successBlock, responseObject);
    GS_SAFE_BLOCK(request.finishedBlock, responseObject, nil);
    [request cleanCallbackBlocks];
}

- (void)gs_failureWithError:(NSError *)error forRequest:(GSRequest *)request {
    
    if (self.consoleLog) {
        NSLog(@"\n=========== [GSResponse Error] ===========\nrequest url: %@ \nerror info: \n%@\n==========================================\n", request.url, error);
    }
    
    GS_SAFE_BLOCK(self.errorProcessHandler, request, &error);
    
    if (request.retryCount > 0) {
        request.retryCount --;
        // retry current request after 2 seconds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self gs_sendRequest:request];
        });
        return;
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf gs_execureFailureBlockWithError:error forRequest:request];
        });
    } else {
        // execure failure block in a private concurrent dispatch queue.
        [self gs_execureFailureBlockWithError:error forRequest:request];
    }
}

- (void)gs_execureFailureBlockWithError:(NSError *)error forRequest:(GSRequest *)request {
    GS_SAFE_BLOCK(request.failureBlock, error);
    GS_SAFE_BLOCK(request.finishedBlock, nil, error);
    [request cleanCallbackBlocks];
}

- (NSString *)gs_identifierForBatchAndChainRequest {
    NSString *identifier = nil;
    GSLock();
    self.autoIncrement++;
    identifier = [NSString stringWithFormat:@"BC%lu", (unsigned long)self.autoIncrement];
    GSUnlock();
    return identifier;
}

#pragma mark - Accessor

- (NSMutableDictionary<NSString *, id> *)runningBatchAndChainPool {
    if (!_runningBatchAndChainPool) {
        _runningBatchAndChainPool = [NSMutableDictionary dictionary];
    }
    return _runningBatchAndChainPool;
}

- (NSMutableDictionary<NSString *, id> *)generalParameters {
    if (!_generalParameters) {
        _generalParameters = [NSMutableDictionary dictionary];
    }
    return _generalParameters;
}

- (NSMutableDictionary<NSString *, NSString *> *)generalHeaders {
    if (!_generalHeaders) {
        _generalHeaders = [NSMutableDictionary dictionary];
    }
    return _generalHeaders;
}

@end

#pragma mark - GSConfig

@implementation GSConfig
@end
