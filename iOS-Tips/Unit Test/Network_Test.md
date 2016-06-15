## 网络测试

网络测试一般需要我们需要模拟网络请求的各种状态，一般测试请求成功、请求失败、请求超时三种情况，这里我们用[OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)或者[GYHttpMock](https://github.com/hypoyao/GYHttpMock)来模拟网络数据返回。


+	OHHTTPStubs ： 国外的第三方库, 2300+☆
+   GYHttpMock :  国内的微信读书团队开源的库，150+☆


#### 举例

1、使用OHHTTPStubs

```
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
  
  return [request.URL.host isEqualToString:@"www.meitu.com"];
  
} withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
  
  NSString* fixture = OHPathForFile(@"meitu.json", self.class);
  return [OHHTTPStubsResponse responseWithFileAtPath:fixture
            statusCode:200 headers:@{@"Content-Type":@"application/json"}];
}];

```

host为`www.meitu.com`的请求,都会被截获,返回的数据会被本地的`meitu.json`数据代替，响应码为`200`、请求头为`application/json`

具体能够响应的数据和方法[参考这里](https://github.com/AliSoftware/OHHTTPStubs/blob/master/OHHTTPStubs/Sources/OHHTTPStubsResponse.h)

2、使用GYHttpMock

注册需要被截获的请求

```
	 mockRequest(@"GET", @"http://www.meitu.com")
    .withBody(@"{\"name\":\"abc\"}")
    .andReturn(201)
    .withBody(@"{\"key\":\"value\"}");
```

这里能够直接截获`http://www.meitu.com`的请求，返回响应码为`201`, 返回内容是`{\"key\":\"value\"}`的json内容。

上面两种都是截获了请求,返回了自定义的数据, 用法不一样，可以选择适合的。

#### 参考资料
1、[GYHttpMock](https://github.com/hypoyao/GYHttpMock)

2、[OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)