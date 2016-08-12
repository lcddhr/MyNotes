### MTUIKit
* 简介
	基于UIKit自定义控件封装

#### 联系人
|联系人|角色|QQ|邮箱|
|:-:|:-:|:-:|:-:|
|彭浩|iOS组件负责人|496124577|ph@meitu.com|

#### 控件(分类)列表——各控件详细信息见其对应的readme文档
* [MTUIImageScrollView](Document/MTUIImageScrollView.md)
根据图片按照填充屏幕放大图片并且显示像素网格
* [UIWebView+MTCustomUserAgent](Document/UIWebView+MTCustomUserAgent.md)
userAgent中包含APP及系统等信息自定义UIWebView


组件展示
==========================
Repo | Demo
:------: | :------:
<center>[MTBubbleView](Document/MTBubbleView.md) <br> <br> 美图秀秀项目中抽离出来的贴纸组件, 提供水平翻转、手势缩放旋转、单指缩放旋转功能<br> <br> 组件维护人: lcd <br> QQ: 122167358 <br><br>[使用文档](Document/MTBubbleView.md) <br></center>| <img src="Sources/MTBubbleView.gif">


### 使用说明
#### 环境要求
* iOS版本要求: >= 7.0

#### 测试分支接入
	pod 'MTUIKit', :git => 'http://techgit.meitu.com/iosmodules/MTUIKit.git', :branch => '~> 0.2.0'

#### 接入步骤
* 整个MTUIKit接入：在podfile文件中添加以下内容

		source 'http://techgit.meitu.com/iosmodules/specs.git'

		target 'targetName' do
			pod 'MTUIKit', '~> 0.2.0'
		end

* 需要使用地方引入头文件

		#import 'MTUIKit.h'

* 单个控件接入以及使用见**控件(分类)列表**中介绍对应控件的ReadMe文档。

* 具体使用参考项目Demo

#### 版本更新历史

* **0.2.0** -- 2016.7.8  修改UIWebView的UserAgent字段添加自定义美图标识方案，删除MTUIWebView，替换为UIWebView+MTCustomUserAgent分类。

* **0.1.0** -- 2016.7.1  第一个版本添加MTUIWebView，在UserAgent字段中添加自定义美图标识信息。