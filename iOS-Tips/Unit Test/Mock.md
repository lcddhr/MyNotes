## Mock

单元测试要保证尽可能少实例化一些具体的组件，保证测试类与其他类对象的隔离。Mock就是伪造一个预定义行为的具体对象。

这里我们选择的库是[OCMock](https://github.com/erikdoe/ocmock)

##用法介绍
#### Class mocks

```
	id classMock = OCMClassMock([SomeClass class]);
```

#### Protocol mocks

```
	id protocolMock = OCMProtocolMock(@protocol(SomeProtocol));
```

#### Strict class and protocol mocks

```
id classMock = OCMStrictClassMock([SomeClass class]);
id protocolMock = OCMStrictProtocolMock(@protocol(SomeProtocol));
```

#### Observer mocks

```
	id observerMock = OCMObserverMock();
```

#### OCMStrictClassMock 和 OCMClassMock区别

+	OCMStrictClassMock：如果stub方法没有按照期望调用，抛出异常
+ 	OCMClassMock： 如果stub方法没有按照期望调用，返回nil


#### Stub

stub是替换Mock对象特定的行为或者属性，可以理解为按照我们的意愿去改造类。

举个例子：这里定义了一个`Car`类, 里面有一个`carName `方法能够返回车的名字。

`OCMStub `是一个宏,来实现stub的功能,下面这里是让方法返回的值为`BMW`;

```

//car类:
- (NSString *)carName {

    return @"BMW";
}

//stub:
id myCar = OCMClassMock([Car class]);
OCMStub([mock carName]).andReturn(@"BMW");
```

#### 验证方法调用

`OCMVerify`用来验证方法是否被调用的功能,遵循先运行后验证的原则。

举个例子,`Son`类里面有`buyCar：`方法，需要传入一个`car`对象，方法里调用了`car`对象的`carName`方法。`Son`不关心`car`调用`carName`里面具体实现，只关心`carName`这个方法有没有具体被调用

因为Car属于具体的类，为了测试隔离其他测试类，我们这里用mock的形式生成Car对象，然后再检查buyCar里面的行为是否被正确调用

```
car类:
- (NSString *)carName {

    return @"BMW";
}

son类：
- (void)buyCar:(Car *)car {
    
    [car carName];
}

测试：
- (void)testCarName {
    
    id mock = OCMClassMock([Car class]);
    Son *son = [[Son alloc] init];
    
    //先运行
    [son buyCar:mock];

    //后验证
    OCMVerify([mock carName]);
}
```

#### mock类方法

```
id classMock = OCMClassMock([SomeClass class]);
OCMStub([classMock aClassMethod]).andReturn(@"Test string");

// result is @"Test string"
NSString *result = [SomeClass aClassMethod];
```

#### Delegating to another method

```
OCMStub([mock someMethod]).andCall(anotherObject, @selector(aDifferentMethod));
```
当`someMethod`方法被调用的时候，`antherObject`会调用`aDifferentMethod`方法

#### Delegating to a block

```
	OCMStub([mock someMethod]).andDo(^(NSInvocation *invocation)
    { /* block that handles the method invocation */ });
```
当`someMethod`方法被调用的时候，block方法会被调用

#### stub block 参数

```
//car 类
- (void)createWithBlock:(CarBlock)block {
    
    if (block) {
        block(@"BMW");
    }
}

//测试
- (void)testBlock {
    
    id mock = OCMClassMock([Car class]);
    OCMStub([mock createWithBlock:([OCMArg invokeBlockWithArgs:@"BENZ", nil])]);
    [mock createWithBlock:^(NSString *name) {
        
        NSLog(@"%@",name);
        
    }];
}

//结果会输出:BENZ
```

#### 抛出异常

```
	OCMStub([mock someMethod]).andThrow(anException);
```

#### 发送通知

```
	OCMStub([mock someMethod]).andPost(aNotification);
```

#### stub 链式调用

```
	OCMStub([mock someMethod]).andPost(aNotification).andReturn(aValue);
```

发送`aNotification `然后返回`aValue `值

#### 注意事项

1. 不要同一时刻mock多个相同对象

```
// don't do this
id mock1 = OCMClassMock([SomeClass class]);
OCMStub([mock1 aClassMethod]);
id mock2 = OCMClassMock([SomeClass class]);
OCMStub([mock2 anotherClassMethod]);
```
mock对象stub方法后在测试完成前一直存在,多次mock相同对象会造成mock生成对象的行为是未定义的。

2. 在stub方法后设置expect相同方法是无效的

```
id mock = OCMStrictClassMock([SomeClass class]);
OCMStub([mock someMethod]).andReturn(@"a string");
OCMExpect([mock someMethod]);

/* run code under test */

OCMVerifyAll(mock); // will complain that someMethod has not been called
```
stub方法后设置expect会导致方法验证失败,认为`someMethod`方法未调用

3. OCMPartialMock不能用来创建特殊的具体对象

```
id partialMockForString = OCMPartialMock(@"Foo"); // will throw an exception

NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
id partialMockForDate = OCMPartialMock(date); // will throw on some architectures
```

`OCMPartialMock`不能用于`toll-free bridged`类对象的创建，例如`NSString`和`NSDate`

4. 不能mock确定的runtime方法.

	+	init
	+  class
	+  methodSignatureForSelector
	+  forwardInvocation

5. `NSString`和`NSArray`方法不能stub或者验证.

6. `NSObject` 不能被验证

7. 私有类的方法不能验证

8. 运行后验证不能使用延迟

9. OCMock并不全是线程安全的,

## 参考资料
1. [http://ocmock.org/reference/](http://ocmock.org/reference/)
