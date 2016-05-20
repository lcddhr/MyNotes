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