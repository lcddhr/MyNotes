#ifndef GSConst_h
#define GSConst_h

#define GS_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })
#define GSLock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define GSUnlock() dispatch_semaphore_signal(self->_lock)

NS_ASSUME_NONNULL_BEGIN

@class GSRequest, GSBatchRequest, GSChainRequest;

/**
 Types enum for GSRequest.
 */
typedef NS_ENUM(NSInteger, GSRequestType) {
    kGSRequestNormal    = 0,    //!< Normal HTTP request type, such as GET, POST, ...
    kGSRequestUpload    = 1,    //!< Upload request type
    kGSRequestDownload  = 2,    //!< Download request type
};

/**
 HTTP methods enum for GSRequest.
 */
typedef NS_ENUM(NSInteger, GSHTTPMethodType) {
    kGSHTTPMethodGET    = 0,    //!< GET
    kGSHTTPMethodPOST   = 1,    //!< POST
    kGSHTTPMethodHEAD   = 2,    //!< HEAD
    kGSHTTPMethodDELETE = 3,    //!< DELETE
    kGSHTTPMethodPUT    = 4,    //!< PUT
    kGSHTTPMethodPATCH  = 5,    //!< PATCH
};

/**
 Resquest parameter serialization type enum for GSRequest, see `AFURLRequestSerialization.h` for details.
 */
typedef NS_ENUM(NSInteger, GSRequestSerializerType) {
    kGSRequestSerializerRAW     = 0,    //!< Encodes parameters to a query string and put it into HTTP body, setting the `Content-Type` of the encoded request to default value `application/x-www-form-urlencoded`.
    kGSRequestSerializerJSON    = 1,    //!< Encodes parameters as JSON using `NSJSONSerialization`, setting the `Content-Type` of the encoded request to `application/json`.
    kGSRequestSerializerPlist   = 2,    //!< Encodes parameters as Property List using `NSPropertyListSerialization`, setting the `Content-Type` of the encoded request to `application/x-plist`.
};

/**
 Response data serialization type enum for GSRequest, see `AFURLResponseSerialization.h` for details.
 */
typedef NS_ENUM(NSInteger, GSResponseSerializerType) {
    kGSResponseSerializerRAW    = 0,    //!< Validates the response status code and content type, and returns the default response data.
    kGSResponseSerializerJSON   = 1,    //!< Validates and decodes JSON responses using `NSJSONSerialization`, and returns a NSDictionary/NSArray/... JSON object.
    kGSResponseSerializerPlist  = 2,    //!< Validates and decodes Property List responses using `NSPropertyListSerialization`, and returns a property list object.
    kGSResponseSerializerXML    = 3,    //!< Validates and decodes XML responses as an `NSXMLParser` objects.
};

/**
 Network connection type enum
 */
typedef NS_ENUM(NSInteger, GSNetworkConnectionType) {
    kGSNetworkConnectionTypeUnknown          = -1,
    kGSNetworkConnectionTypeNotReachable     = 0,
    kGSNetworkConnectionTypeViaWWAN          = 1,
    kGSNetworkConnectionTypeViaWiFi          = 2,
};

///------------------------------
/// @name GSRequest Config Blocks
///------------------------------

typedef void (^GSRequestConfigBlock)(GSRequest *request);
typedef void (^GSBatchRequestConfigBlock)(GSBatchRequest *batchRequest);
typedef void (^GSChainRequestConfigBlock)(GSChainRequest *chainRequest);

///--------------------------------
/// @name GSRequest Callback Blocks
///--------------------------------

typedef void (^GSProgressBlock)(NSProgress *progress);
typedef void (^GSSuccessBlock)(id _Nullable responseObject);
typedef void (^GSFailureBlock)(NSError * _Nullable error);
typedef void (^GSFinishedBlock)(id _Nullable responseObject, NSError * _Nullable error);
typedef void (^GSCancelBlock)(id _Nullable request); // The `request` might be a GSRequest/GSBatchRequest/GSChainRequest object.

///-------------------------------------------------
/// @name Callback Blocks for Batch or Chain Request
///-------------------------------------------------

typedef void (^GSBCSuccessBlock)(NSArray *responseObjects);
typedef void (^GSBCFailureBlock)(NSArray *errors);
typedef void (^GSBCFinishedBlock)(NSArray * _Nullable responseObjects, NSArray * _Nullable errors);
typedef void (^GSBCNextBlock)(GSRequest *request, id _Nullable responseObject, BOOL *isSent);

///------------------------------
/// @name GSCenter Process Blocks
///------------------------------

/**
 The custom request pre-process block for all GSRequests invoked by GSCenter.
 
 @param request The current GSRequest object.
 */
typedef void (^GSCenterRequestProcessBlock)(GSRequest *request);

/**
 The custom response process block for all GSRequests invoked by GSCenter.

 @param request The current GSRequest object.
 @param responseObject The response data return from server.
 @param error The error that occurred while the response data don't conforms to your own business logic.
 */
typedef id (^GSCenterResponseProcessBlock)(GSRequest *request, id _Nullable responseObject, NSError * _Nullable __autoreleasing *error);

/**
 The custom error process block for all GSRequests invoked by GSCenter.
 
 @param request The current GSRequest object.
 @param error The error that occurred while the response data don't conforms to your own business logic.
 */
typedef void (^GSCenterErrorProcessBlock)(GSRequest *request, NSError * _Nullable __autoreleasing *error);

NS_ASSUME_NONNULL_END

#endif /* GSConst_h */
