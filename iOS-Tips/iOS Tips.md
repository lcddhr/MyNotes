## 1.iOS查找字符串替换

+	1.打开Find Navigator	
+	2.找到Regular Expression
+	输入`@"[^"]*[\u4E00-\u9FA5]+[^"\n]*?"`

** 替换NSLocalizedString的comment **

+	1. Find `NSLocalizedString\((@"[^\)]*?")\s*,\s*@"[^\)]*"\s*\)`
+	2. Replace With Replace With `NSLocalizedString\($1, nil\)`


## 2.AutoLayout更新约束的时机

1. `updateViewConstraints`里面，在`loadView`方法后面调用`[self.view setNeedsUpdateConstraints]`,并且增加开关控制，避免重复加。参考[stackoverflow回答](http://stackoverflow.com/questions/19387998/where-should-i-be-setting-autolayout-constraints-when-creating-views-programatic)
2. 写在`viewDidload`里面，参考[这篇文章](http://casatwy.com/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-an.html)

## 3.扩大View的点击区域

参考资料:[这里](http://kittenyang.com/effective_category/)

```
	void Swizzle(Class c, SEL orig, SEL new) {  
  Method origMethod = class_getInstanceMethod(c, orig);
  Method newMethod = class_getInstanceMethod(c, new);
  if (class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))){
    class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
  } else {
    method_exchangeImplementations(origMethod, newMethod);
  }
}

@implementation UIView (ExtendTouchRect)

+ (void)load {
  Swizzle(self, @selector(pointInside:withEvent:), @selector(myPointInside:withEvent:));
}

- (BOOL)myPointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if (UIEdgeInsetsEqualToEdgeInsets(self.touchExtendInset, UIEdgeInsetsZero) || self.hidden ||
      ([self isKindOfClass:UIControl.class] && !((UIControl *)self).enabled)) {
    return [self myPointInside:point withEvent:event]; // original implementation
  }
  CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, self.touchExtendInset);
  hitFrame.size.width = MAX(hitFrame.size.width, 0); // don't allow negative sizes
  hitFrame.size.height = MAX(hitFrame.size.height, 0);
  return CGRectContainsPoint(hitFrame, point);
}

static char touchExtendInsetKey;  
- (void)setTouchExtendInset:(UIEdgeInsets)touchExtendInset {
  objc_setAssociatedObject(self, &touchExtendInsetKey, [NSValue valueWithUIEdgeInsets:touchExtendInset],
                           OBJC_ASSOCIATION_RETAIN);
}

- (UIEdgeInsets)touchExtendInset {
  return [objc_getAssociatedObject(self, &touchExtendInsetKey) UIEdgeInsetsValue];
}

@end
```

## 4.镂空文字，类似歌曲进度显示文字

参考资料[这里](http://www.jianshu.com/p/93592bdc99c6)

## 5. TableView的封装
参考资料[这里](https://github.com/bestswifter/MySampleCode/tree/master/KtTableView)


## 6.file's owner and custom class区别

`File's owner`：加载xib的对象，能够接收到loadNibNamed:或者是initWithNibName:消息


## 7. xib的嵌套使用

把自定义xib对象的`custom class` 取消换成`file's owner`, 这里的xib只是一个容器对象。

在`initWitCoder`里面把xib的内容加载上去

```
	- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        UIView *containerView = [[[UINib nibWithNibName:@"DDView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
        CGRect newFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        containerView.frame = newFrame;
        [self addSubview:containerView];
    }
    return self;
}
```


然后在需要使用到这个对象的xib内的custom class定义成这个对象的类


## 8. Pod intsll 和 Pod update 区别

+	pod install:  下载并且安装新的 pod，将安装的 pod 信息写入 `Podfile.lock`
	+	对于已经在 Podfile.lock 中的 pod，它会下载在 Podfile.lcok 中指示的版本，不会去检查有没有新版本
	+	对于没有出现在 Podfile.lock 中的 pod，它会搜索符合 Podfile 中要求的版本

+	pod update:

	+	当你执行 pod update SomePodName 的时候， CocoaPods 会试着找到一个更新的 SomePodName，不会理会已经在 Podfile.lock 中已经存在的版本。在满足 Podfile 中对版本的约束的情况下，它会试图把 pod 更新到尽可能新的版本。

	+	如果你只执行 pod update 后面没有跟任何 pod 的名字，CocoaPods 会把 Podfile 中所有列出的 pod 都更新到尽可能新的版本。
	
## 9. XCTAssertEqualWithAccuracy
判断相等，提供一个误差范围

## 10. Pod Search失效

CompatibilityError: incompatible character encodings: UTF-8 and ASCII-8BIT

删除`~/Library/Caches/CocoaPods/search_index.json`文件

## 11. 获取图片所占用的内存

```
	- (size_t) memorySize:(UIImage *)image
{
    CGImageRef temp = image.CGImage;
    size_t instanceSize = class_getInstanceSize(image.class);
    size_t pixmapSize = CGImageGetHeight(temp) * CGImageGetBytesPerRow(temp);
    size_t totalSize = instanceSize + pixmapSize;
    return totalSize;
}
```

## 12.移除视图的时候也要移除约束

## 13 setNeedsLayout 和 layoutIfNeeded区别
+	setNeedsLayout： 标记为页面需要更新，但不立即执行. 将来某个时刻调用layoutIfNeeded之后会调用系统的layoutSubviews。

+	layoutIfNeeded：立即更新

如果想要立即改变约束, 调用setNeedsLayout

如果想要立即改变布局, 形成frame， 调用layoutIfNeeded

## 14、User Header Search Paths 和Header Search Paths区别

Use the User Header Search Paths for paths you want searched for `#include "..."` and use the Header Search Paths for `#include <...>.` Of course, if you check the option to Always Search User Paths, then #include <...> will also work for the user paths.

## 15、防止按钮被重复点击

```
- (void)executeOperation:(void(^)())operation withDelayForRepeatClick:(NSTimeInterval)delay

{

    self.userInteractionEnabled = NO;

    operation();

    __weak typeof(self) weakSelf = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        weakSelf.userInteractionEnabled = YES;

    });

}
```

## 16、防止循环引用

+	 __weak和 __strong

+	像pop里面声明的一样， 增加个target	

```
	typedef BOOL (^POPCustomAnimationBlock)(id target, POPCustomAnimation *animation);
	
```

## 17. 在Xcode里面查看某行代码是谁提交的

```
	右键  -> Show Blame for Line
```


## 18. removeFromSuperview的理解

执行这个方法后, 会从父视图中移除, 并且将superview对视图的强引用也删除, 如果此时没有其他地方再对视图进行强引用, 则会从内存中移除. 如果还存在其他强引用, 视图只是不再品目中显示, 并没有将该视图从内存中移除。 如果还需要再次创建, 直接`addSubview`就可以了。

参考:[http://www.jianshu.com/p/b817c94cac0b](http://www.jianshu.com/p/b817c94cac0b)