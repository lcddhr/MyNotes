## Gitflow工作流

+	master: 稳定版、打tag
+  develop: 功能的集成分支
+  feature: 只能从develop分支上拉出, 功能完成时候合并回develop分支
+  release: 一旦`develop`分支上有做一次发布, 就从`develop`分支`fork`一个发布分支。 这个分支只做bug修复、文档生成和其他面向发布的任务. 一旦对外发布的工作都完成了, 发布分支需要合并到`master`分支并分配一个版本号打好tag. 这些发布分支上的修改要合并回`develop`分支.
+  hotfix: 修复发布版本的bug, 从`master`分支fork出来。修复完成应该马上合并回master和develop分支, `master`分支应该使用新的版本号, 打好tag. 为bug修复使用专门的分支, 可以让团队处理到问题不影响其他工作, 或者等待下一个版本发布。

使用一个发布准备的专门分支, 使得一个团队可以在完善当前发布版本的同时, 另外一个团队可以继续下个版本的功能。


#### 命名
```
	发布分支: release/1.0.0 , 只能从develop上拉取
	bug:	  hotfix:/1.0.0-#245-bug描述
	
```

## 参考资料
[http://blog.jobbole.com/76867/](http://blog.jobbole.com/76867/)