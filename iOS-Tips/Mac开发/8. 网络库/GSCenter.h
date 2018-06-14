#import <Foundation/Foundation.h>
#import "GSConst.h"

NS_ASSUME_NONNULL_BEGIN

@class GSConfig, GSEngine;

/**
 `GSCenter` is a global central place to send and manage all network requests.
 `+center` method is used to creates a new `GSCenter` object,
 `+defaultCenter` method will return a default shared `GSCenter` singleton object.
 
 The class methods for `GSCenter` are invoked by `[GSCenter defaultCenter]`, which are recommend to use `Class Method` instead of manager a `GSCenter` yourself.
 
 Usage:
 
 (1) Config GSCenter
 
 [GSCenter setupConfig:^(GSConfig *config) {
     config.server = @"general server address";
     config.headers = @{@"general header": @"general header value"};
     config.parameters = @{@"general parameter": @"general parameter value"};
     config.callbackQueue = dispatch_get_main_queue(); // set callback dispatch queue
 }];
 
 [GSCenter setRequestProcessBlock:^(GSRequest *request) {
     // Do the custom request pre processing logic by yourself.
 }];
 
 [GSCenter setResponseProcessBlock:^(GSRequest *request, id responseObject, NSError *__autoreleasing *error) {
     // Do the custom response data processing logic by yourself.
     // You can assign the passed in `error` argument when error occurred, and the failure block will be called instead of success block.
 }];
 
 (2) Send a Request
 
 [GSCenter sendRequest:^(GSRequest *request) {
     request.server = @"server address"; // optional, if `nil`, the genneal server is used.
     request.api = @"api path";
     request.parameters = @{@"param1": @"value1", @"param2": @"value2"}; // and the general parameters will add to reqeust parameters.
 } onSuccess:^(id responseObject) {
     // success code here...
 } onFailure:^(NSError *error) {
     // failure code here...
 }];
 
 */
@interface GSCenter : NSObject

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a new `GSCenter` object.
 */
+ (instancetype)center;

/**
 Returns the default shared `GSCenter` singleton object.
 */
+ (instancetype)defaultCenter;

///-----------------------
/// @name General Property
///-----------------------

// NOTE: The following properties could only be assigned by `GSConfig` through invoking `-setupConfig:` method.

/**
 The general server address for GSCenter, if GSRequest.server is `nil` and the GSRequest.useGeneralServer is `YES`, this property will be assigned to GSRequest.server.
 */
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general parameters for GSCenter, if GSRequest.useGeneralParameters is `YES` and this property is not empty, it will be appended to GSRequest.parameters.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, id> *generalParameters;

/**
 The general headers for GSCenter, if GSRequest.useGeneralHeaders is `YES` and this property is not empty, it will be appended to GSRequest.headers.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

/**
 The general user info for GSCenter, if GSRequest.userInfo is `nil` and this property is not `nil`, it will be assigned to GSRequest.userInfo.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 The dispatch queue for callback blocks. If `NULL` (default), a private concurrent queue is used.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The global requests engine for current GSCenter object, `[GSEngine sharedEngine]` by default.
 */
@property (nonatomic, strong) GSEngine *engine;

/**
 Whether or not to print the request and response info in console, `NO` by default.
 */
@property (nonatomic, assign) BOOL consoleLog;

///--------------------------------------------
/// @name Instance Method to Configure GSCenter
///--------------------------------------------

#pragma mark - Instance Method

/**
 Method to config the GSCenter properties by a `GSConfig` object.

 @param block The config block to assign the values for `GSConfig` object.
 */
- (void)setupConfig:(void(^)(GSConfig *config))block;

/**
 Method to set custom request pre processing block for GSCenter.
 
 @param block The custom processing block (`GSCenterRequestProcessBlock`).
 */
- (void)setRequestProcessBlock:(GSCenterRequestProcessBlock)block;

/**
 Method to set custom response data processing block for GSCenter.

 @param block The custom processing block (`GSCenterResponseProcessBlock`).
 */
- (void)setResponseProcessBlock:(GSCenterResponseProcessBlock)block;

/**
 Method to set custom error processing block for GSCenter.
 
 @param block The custom processing block (`GSCenterErrorProcessBlock`).
 */
- (void)setErrorProcessBlock:(GSCenterErrorProcessBlock)block;

/**
 Sets the value for the general HTTP headers of GSCenter, If value is `nil`, it will remove the existing value for that header field.
 
 @param value The value to set for the specified header, or `nil`.
 @param field The HTTP header to set a value for.
 */
- (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;

/**
 Sets the value for the general parameters of GSCenter, If value is `nil`, it will remove the existing value for that parameter key.
 
 @param value The value to set for the specified parameter, or `nil`.
 @param key The parameter key to set a value for.
 */
- (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

///---------------------------------------
/// @name Instance Method to Send Requests
///---------------------------------------

#pragma mark -

/**
 Creates and runs a Normal `GSRequest`.

 @param configBlock The config block to setup context info for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock;

/**
 Creates and runs a Normal `GSRequest` with success block.
 
 NOTE: The success block will be called on `callbackQueue` of GSCenter.

 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param successBlock Success callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock;

/**
 Creates and runs a Normal `GSRequest` with failure block.
 
 NOTE: The failure block will be called on `callbackQueue` of GSCenter.

 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param failureBlock Failure callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

/**
 Creates and runs a Normal `GSRequest` with finished block.

 NOTE: The finished block will be called on `callbackQueue` of GSCenter.
 
 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param finishedBlock Finished callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

/**
 Creates and runs a Normal `GSRequest` with success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of GSCenter.
 
 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param successBlock Success callback block for the new created GSRequest object.
 @param failureBlock Failure callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

/**
 Creates and runs a Normal `GSRequest` with success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of GSCenter.
 
 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param successBlock Success callback block for the new created GSRequest object.
 @param failureBlock Failure callback block for the new created GSRequest object.
 @param finishedBlock Finished callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

/**
 Creates and runs an Upload/Download `GSRequest` with progress/success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of GSCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of GSCenter.
 
 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param progressBlock Progress callback block for the new created GSRequest object.
 @param successBlock Success callback block for the new created GSRequest object.
 @param failureBlock Failure callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onProgress:(nullable GSProgressBlock)progressBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

/**
 Creates and runs an Upload/Download `GSRequest` with progress/success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of GSCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of GSCenter.
 
 @param configBlock The config block to setup context info for the new created GSRequest object.
 @param progressBlock Progress callback block for the new created GSRequest object.
 @param successBlock Success callback block for the new created GSRequest object.
 @param failureBlock Failure callback block for the new created GSRequest object.
 @param finishedBlock Finished callback block for the new created GSRequest object.
 @return Unique identifier for the new running GSRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onProgress:(nullable GSProgressBlock)progressBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

/**
 Creates and runs batch requests

 @param configBlock The config block to setup batch requests context info for the new created GSBatchRequest object.
 @param successBlock Success callback block called when all batch requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created GSBatchRequest object.
 @return Unique identifier for the new running GSBatchRequest object,`nil` for fail.
 */
- (nullable NSString *)sendBatchRequest:(GSBatchRequestConfigBlock)configBlock
                              onSuccess:(nullable GSBCSuccessBlock)successBlock
                              onFailure:(nullable GSBCFailureBlock)failureBlock
                             onFinished:(nullable GSBCFinishedBlock)finishedBlock;

/**
 Creates and runs chain requests

 @param configBlock The config block to setup chain requests context info for the new created GSBatchRequest object.
 @param successBlock Success callback block called when all chain requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created GSChainRequest object.
 @return Unique identifier for the new running GSChainRequest object,`nil` for fail.
 */
- (nullable NSString *)sendChainRequest:(GSChainRequestConfigBlock)configBlock
                              onSuccess:(nullable GSBCSuccessBlock)successBlock
                              onFailure:(nullable GSBCFailureBlock)failureBlock
                             onFinished:(nullable GSBCFinishedBlock)finishedBlock;

///------------------------------------------
/// @name Instance Method to Operate Requests
///------------------------------------------

#pragma mark -

/**
 Method to cancel a runnig request by identifier.
 
 @param identifier The unique identifier of a running request.
 */
- (void)cancelRequest:(NSString *)identifier;

/**
 Method to cancel a runnig request by identifier with a cancel block.
 
 NOTE: The cancel block is called on current thread who invoked the method, not the `callbackQueue` of GSCenter.
 
 @param identifier The unique identifier of a running request.
 @param cancelBlock The callback block to be executed after the running request is canceled. The canceled request object (if exist) will be passed in argument to the cancel block.
 */
- (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable GSCancelBlock)cancelBlock;

/**
 Method to get a runnig request object matching to identifier.
 
 @param identifier The unique identifier of a running request.
 @return return The runing GSRequest/GSBatchRequest/GSChainRequest object (if exist) matching to identifier.
 */
- (nullable id)getRequest:(NSString *)identifier;

/**
 Method to get current network reachablity status.
 
 @return The network is reachable or not.
 */
- (BOOL)isNetworkReachable;

/**
 Method to get current network connection type.
 
 @return The network connection type, see `GSNetworkConnectionType` for details.
 */
- (GSNetworkConnectionType)networkConnectionType;

///--------------------------------
/// @name Class Method for GSCenter
///--------------------------------

// NOTE: The following class method is invoke through the `[GSCenter defaultCenter]` singleton object.

#pragma mark - Class Method

+ (void)setupConfig:(void(^)(GSConfig *config))block;
+ (void)setRequestProcessBlock:(GSCenterRequestProcessBlock)block;
+ (void)setResponseProcessBlock:(GSCenterResponseProcessBlock)block;
+ (void)setErrorProcessBlock:(GSCenterErrorProcessBlock)block;
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;
+ (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

#pragma mark -

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onProgress:(nullable GSProgressBlock)progressBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(GSRequestConfigBlock)configBlock
                        onProgress:(nullable GSProgressBlock)progressBlock
                         onSuccess:(nullable GSSuccessBlock)successBlock
                         onFailure:(nullable GSFailureBlock)failureBlock
                        onFinished:(nullable GSFinishedBlock)finishedBlock;

+ (nullable NSString *)sendBatchRequest:(GSBatchRequestConfigBlock)configBlock
                              onSuccess:(nullable GSBCSuccessBlock)successBlock
                              onFailure:(nullable GSBCFailureBlock)failureBlock
                             onFinished:(nullable GSBCFinishedBlock)finishedBlock;

+ (nullable NSString *)sendChainRequest:(GSChainRequestConfigBlock)configBlock
                              onSuccess:(nullable GSBCSuccessBlock)successBlock
                              onFailure:(nullable GSBCFailureBlock)failureBlock
                             onFinished:(nullable GSBCFinishedBlock)finishedBlock;

#pragma mark -

+ (void)cancelRequest:(NSString *)identifier;

+ (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable GSCancelBlock)cancelBlock;

+ (nullable id)getRequest:(NSString *)identifier;

+ (BOOL)isNetworkReachable;

+ (GSNetworkConnectionType)networkConnectionType;

#pragma mark -

+ (void)addSSLPinningURL:(NSString *)url;
+ (void)addSSLPinningCert:(NSData *)cert;
+ (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password;

@end

#pragma mark - GSConfig

/**
 `GSConfig` is used to assign values for GSCenter's properties through invoking `-setupConfig:` method.
 */
@interface GSConfig : NSObject

///-----------------------------------------------
/// @name Properties to Assign Values for GSCenter
///-----------------------------------------------

/**
The general server address to assign for GSCenter.
*/
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general parameters to assign for GSCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;

/**
 The general headers to assign for GSCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;

/**
 The general user info to assign for GSCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 The dispatch callback queue to assign for GSCenter.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The global requests engine to assign for GSCenter.
 */
@property (nonatomic, strong, nullable) GSEngine *engine;

/**
 The console log BOOL value to assign for GSCenter.
 */
@property (nonatomic, assign) BOOL consoleLog;

@end

NS_ASSUME_NONNULL_END
