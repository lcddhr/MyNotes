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


