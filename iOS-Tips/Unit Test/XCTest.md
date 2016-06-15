## XCTest 介绍

#### 测试文件结构

+	`setUp`: 测试前的准备工作,例如需要初始化一些测试的数据、临时变量
+ 	`tearDown`: 测试结束后的操作, 例如释放内存
+  `testPerformanceExample`: 性能测试。


#### 测试用例命名
```
	test + 测试对象的行为
```

官方规定测试用例都是以`test`开头, 标识是一个单独的测试用例。

举例：给定两个数，测试这两个数的和是否等于20

```
- (void)testAddTowNumber {
    
    //give
    NSInteger a =  10;
    NSInteger b =  20;
    
    //when
    NSInteger count = a + b;
    
    //then
    XCTAssertEqual(count , 20, @"两个数不相等");
}
```

这里使用三段式的方法写测试用例：

`give`: 给定一些数据，一般是创建对象、设定测试的环境

`when`: 对数据进行处理, 一般是调用接口,包含测试的代码

`then`: 检查我们调用接口后的接口是否符合我们的期望,如果出错则使用断言抛出异常。常用的断言请看下面的附录。

#### 异步测试

```
	- (void)testProtocalMethodWriteImageAtURLToSavedPhotosAlbum {
    
    XCTAssertTrue(RESPONED_TO_SELECTOR(@selector(writeImageAtURLToSavedPhotosAlbum:completeBlock:)), @"必须实现writeImageAtURLToSavedPhotosAlbum:completeBlock:方法");
    
    XCTestExpectation * expectation = [self expectationWithDescription:@"保存沙盒目录下的image"];
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    
    [photoLibrary writeImageAtURLToSavedPhotosAlbum:url completeBlock:^(BOOL success, NSArray<NSString *> *changedLocalIdentifiers, NSError *error) {
        
        XCTAssertTrue(success, @"图片保存失败");
        [expectation fulfill];
    }];
    
    //设置超时时间,目的是等待block里面expectation发送fulfill消息, 类似于信号量
    [self waitForExpectationsWithTimeout:kTestTimeOut handler:^(NSError * _Nullable error) {
        
    }];
}
```

这里封装了一个宏定义,只需要在异步测试代码里面添加`WAIT`, 外部添加`NOTIFY`即可

```
#define WAIT                                                                \
do {                                                                        \
[self expectationForNotification:@"MTUnitTest" object:nil handler:nil]; \
[self waitForExpectationsWithTimeout:60 handler:nil];                   \
} while(0);

#define NOTIFY                                                                            \
do {                                                                                      \
[[NSNotificationCenter defaultCenter] postNotificationName:@"MTUnitTest" object:nil]; \
} while(0);
```

如果使用上面宏定义的话, 上面的测试用例变成：

```
	- (void)testProtocalMethodWriteImageAtURLToSavedPhotosAlbum {
    
    XCTAssertTrue(RESPONED_TO_SELECTOR(@selector(writeImageAtURLToSavedPhotosAlbum:completeBlock:)), @"必须实现writeImageAtURLToSavedPhotosAlbum:completeBlock:方法");
    
    XCTestExpectation * expectation = [self expectationWithDescription:@"保存沙盒目录下的image"];
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    
    [photoLibrary writeImageAtURLToSavedPhotosAlbum:url completeBlock:^(BOOL success, NSArray<NSString *> *changedLocalIdentifiers, NSError *error) {
        
        XCTAssertTrue(success, @"图片保存失败");
		 NOTIFY
    }];
	WAIT;
}
```
#### 附录

```
//生成一个失败的测试
XCTFail(format…)  

//是否为空判断，a1为空时通过，反之不通过
XCTAssertNil(a1, format...)  

//不为空判断，a1不为空时通过，反之不通过
XCTAssertNotNil(a1, format…) 

//当expression求值为TRUE时通过
XCTAssert(expression, format...) 

//当expression求值为TRUE时通过
XCTAssertTrue(expression, format...) 

//当expression求值为False时通过
XCTAssertFalse(expression, format...) 

//判断相等，a1和a2相等为TRUE时通过，其中一个不为空时，不通过；
XCTAssertEqualObjects(a1, a2, format...)  

//判断不等，a1和a2不等为False时通过
XCTAssertNotEqualObjects(a1, a2, format...) 

//判断相等 
XCTAssertEqual(a1, a2, format...) 

//判断不等（当a1和a2是C语言标量、结构体或联合体时使用）；
XCTAssertNotEqual(a1, a2, format...)  

//判断相等（double或float类型）提供一个误差范围，当在误差范围（+/-accuracy）以内相等时通过测试；
XCTAssertEqualWithAccuracy(a1, a2, accuracy, format...)  

////判断不等，（double或float类型）提供一个误差范围，当在误差范围以内不等时通过测试；
XCTAssertNotEqualWithAccuracy(a1, a2, accuracy, format...)   

//异常测试，当expression发生异常时通过；反之不通过；
XCTAssertThrows(expression, format...)  

//异常测试，当expression发生specificException异常时通过；反之发生其他异常或不发生异常均不通过；
XCTAssertThrowsSpecific(expression, specificException, format...)  

//异常测试，当expression发生具体异常、具体异常名称的异常时通过测试，反之不通过；
XCTAssertThrowsSpecificNamed(expression, specificException, exception_name, format...)  

//异常测试，当expression没有发生异常时通过测试；
XCTAssertNoThrow(expression, format…)  

//异常测试，当expression没有发生具体异常、具体异常名称的异常时通过测试，反之不通过；
XCTAssertNoThrowSpecific(expression, specificException, format...)  

//异常测试，当expression没有发生具体异常、具体异常名称的异常时通过测试，反之不通过
XCTAssertNoThrowSpecificNamed(expression, specificException, exception_name, format...)  
```

#### 参考资料

1、[http://objccn.io/issue-15-2/](http://objccn.io/issue-15-2/)

2、[http://blog.csdn.net/jymn_chen/article/details/21552941](http://blog.csdn.net/jymn_chen/article/details/21552941)