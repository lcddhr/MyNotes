## 私有库开发规范

#### 创建流程

项目中添加一个新的`feature`来调试开发代码, 以指向branch的形式来下载pod做本地测试

```
pod 'xxx', :git => 'giturl', :branch => 'branch name'
```

测试稳定后, 编写`podspec`文件, 打好测试的tag, 用`lint`方式校验文件是否符合规范。

校验成功后, 删除测试的tag, 然后把`develop`分支代码合并到`master`分支上, 在`master`打稳定版的tag。

最后把`podspec`文件推送到远端

#### 创建的详细步骤

**添加私有库源**

```
	pod repo add REPO_NAME SOURCE_URL
```
+	REPO_NAME: 私有库在本地存放的目录名字。 例如官方的cocoapods名字是`master`, 我们可以在名字前加上公司拼音首字母缩写。
+ SOURCE_URL: 私有库地址

添加成功后可以进入`~/.cocoapods/repos/`目录下面, 可以看到有`REPO_NAME `命名的目录

**制作tag**

进入当前分支的目录

```
	 $ git tag TAG_VERSION  //tag版本
    $ git push --tag	//推送tag到远端
```
tag的命名在测试期间可以加上beta后缀. 例如:`2.0.3-Beta`

稳定版本的直接用3位数. 例如: `2.0.0`

**编写podspec文件**

```
	Pod::Spec.new do |s|
	
  	s.name         = "DDImageUtils"
  	s.version      = "0.0.1.beta"
  	s.summary      = "A custom CollectionView named MTCosmesisControls."
  	s.homepage     = "http://techgit.xxx.com/iosmodules/DDImageUtils"

  	s.license      = {
   	 :type => 'Copyright',
   	 :text => <<-LICENSE
   	           © 2008-2016 Meitu. All rights reserved.
   	 LICENSE
  	}

  	s.author   = { "lcd" => "lcd@qq.com" }

  	s.platform     = :ios, '7.0'
 
  	s.source       = { :git => "http://techgit.xxx.com/iosmodules/DDImageUtils.git", :tag => s.version.to_s }

  	s.source_files  = "DDImageUtils/**/*.{h,m}"

  	s.frameworks = "UIKit"

  	s.requires_arc = true

	end
```

**验证podspec**

```
	pod spec lint xxx.podspec --use-libraries --allow-warnings
```

这里用`pod spec lint`的方式验证, 尽量不要用`pod lib lint`的方式验证, `lib`的验证是走本地的, 不用通过网络, 某些时候会有bug, 例如有配置`xcconfig`的搜索路径, `pod spec lint`可能成功,`pod lib lint`可能失败

*	上传成功后, 如果无法通过`pod search `到自己的库, 需要手动修复, 删除`search_index.json`文件, 重新search。

```
	rm ~/Library/Caches/CocoaPods/search_index.json
```

**导入pod**

```
	platform :ios, '7.0'
	
	source '官方podspec文件的URL'
	source 'podspec文件的SOURCE_URL'

	target 'PROJECT_NAME' do

		pod 'SPEC_NAME', '~> VERSION'

	end
```

**删除pod**
把私有库`spec`clone下来, 找到需要删除的版本,删除之后再push。

#### 注意事项

分目录, 使用subspec

```
	subspec 'Twitter' do |sp|
  		sp.source_files = 'Classes/Twitter'
	end

	subspec 'Pinboard' do |sp|
  		sp.source_files = 'Classes/Pinboard'
	end
```

添加系统的依赖

```
	s.frameworks = "SomeFramework", "AnotherFramework"
    s.libraries = "iconv", "xml2"  
```

添加第三方依赖

```
	s.vendored_frameworks = "SomeFramework", "AnotherFramework"
    s.vendored_library = "iconv", "xml2"  
```

project setting

+	支持ARC:	s.requires_arc = true
+ 	添加依赖库:
	
	```
	s.dependency "JSONKit", "~> 1.4"	//依赖开源的第三方库
	s.dependency "DDKit/subspec"		//依赖subspec
	```

xcconfig	配置

```
s.xcconfig  =  {"USER_HEADER_SEARCH_PATHS" => "${PODS_ROOT}/MTAnalytics//src"}
```

+	文件找不到
	+ 	`#include "..."`或者`#influde <...>`文件找不到
配置xcconfig的时候需要使用`HEADER_SEARCH_PATHS`或者`HEADER_SEARCH_PATHS`两个参数, 两者的区别是
		+	HEADER_SEARCH_PATHS : 针对`#include <...>`形式的引入
		+ USER_HEADER_SEARCH_PATHS: 针对`#include "..."`形式的引入
		+ 另外,还有一个`ALWAYS_SEARCH_USER_PATHS`参数能够同时适合上述两种方式的引入

>	参考资料:[ http://stackoverflow.com/questions/3429031/header-search-paths-vs-user-header-search-paths-in-xcode]( http://stackoverflow.com/questions/3429031/header-search-paths-vs-user-header-search-paths-in-xcode)


其他相关参数: lint或者push的时候使用

* --verbose 查看编译的详情 以理清错误
* --allow-warnings 允许编译警告
* --use-libraries 通常用于避免i386 x86的编译错误
* --sources="SOURCE\_URL, SOURCE_URL" 如果包含私有库的dependency必须加入该参数
