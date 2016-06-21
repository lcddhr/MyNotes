## 功能分支流

#### 工作方式

每次开始新功能前创建一个新的分支。分支的命名应该描述清楚功能。

```
	功能：feature/login
	bug： bugfix/1.0.0-#1061-bug名称  （版本号+bug号+bug名字）
```

#### Pull Request

每次开发完成，push到远端的功能分支上,发起一个`pull request`请求合并到master。这时候其他开发者可以去Review变更。

#### merage

管理者合并的时候需要切换到`master`分支保证是最新的, 然后执行`pull` 保证新开发的功能分支也是最新的，然后再合并。

这样会生成一个合并的提交，像新功能和原来代码基线的连通符。如果需要线性提交, 执行合并的时候rebase新功能到master分支顶部

## 参考资料:

[http://blog.jobbole.com/76857/](http://blog.jobbole.com/76857/)