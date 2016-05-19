## 1.iOS查找字符串替换

+	1.打开Find Navigator	
+	2.找到Regular Expression
+	输入`@"[^"]*[\u4E00-\u9FA5]+[^"\n]*?"`

** 替换NSLocalizedString的comment **

+	1. Find `NSLocalizedString\((@"[^\)]*?")\s*,\s*@"[^\)]*"\s*\)`
+	2. Replace With Replace With `NSLocalizedString\($1, nil\)`
