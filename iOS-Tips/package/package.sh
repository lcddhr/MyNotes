#! /bin/sh

echo "Start to Build...."

# 必须的配置
# 设置 开发，或者发布的根证书全名
distribution_code_sign_name="iPhone Distribution: Peihong Wu (DK9MPZYTDE)"
app_profile_uuid=`/usr/libexec/plistbuddy -c Print:UUID /dev/stdin <<< \ \`security cms -D -i ./PackageProfile.mobileprovision\`` 
echo $app_profile_uuid

#一些路径的切换：切换到你的工程文件目录
cd .. && \
cd PackageDemo &&\


# 设置项目内的Build Version，增1 
plist_file_path=PackageDemo/Info.plist
build_version=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${plist_file_path})
project_build_version=$(expr $build_version + 1)
# 将文件的plist 的build版本号加一，并设置到plist文件中
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $project_build_version" ${plist_file_path} && \

# 生成后，项目导出到哪里
export_path="/Users/meitu/Desktop/PackageDemo"

# 项目名称，xworkspace会用到这个名字
project_name="PackageDemo"

# 工程文件名
project_path="$project_name.xcodeproj"

# 当前是发布，还是开发，或者是你自定义的
configuration="AdHoc"

# 是什么平台，iOS的统一是iphonesos
sdk="iphoneos"

# 可以在manager scheme下面找到当前的scheme
scheme="PackageDemo"

# 声明Build的目录，注意，我这个build文件在这里是因为我改了Xcode里面的Locations的Derived Data：点击advanced，设置Build Location设置为Custom：Relative to Workspace
build_directory="Build/Products"

# Build App文件
build_path="$build_directory/Release-iphoneos/$project_name.app"

# app文件中Info.plist文件路径
app_plist_path=${build_path}/Info.plist

# 版本号
version=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_plist_path})

# Build值
build_version=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_plist_path})

# 需要显示的名字
display_name=$(/usr/libexec/PlistBuddy -c "print CFBundleName" ${app_plist_path})

# IPA名称
ipa_name="${display_name}_${version}(${build_version})_$(date +"%Y%m%d")"

# 导出IPA文件路径
ipa_path="$export_path/$ipa_name.ipa"

# 运行前先clear下项目
xcodebuild clean -workspace $project_name.xcworkspace -scheme $scheme -configuration $configuration && \

# Pod 操作
# pod update

# 进行build，注意APP_PROFILE这个参数，是修改了工程文件buildsetting里面的Provisioning profile里面你设置的对应的configuration的证书为：$APP_PROFILE 才可以这么使用【注意我这个是xcworkspace的，如果有些同学是project文件，请直接使用-project $project_path，相应进行修改】
xcodebuild -workspace $project_name.xcworkspace -scheme $scheme -configuration $configuration -sdk $sdk distribution_code_sign_name="$distribution_code_sign_name" APP_PROFILE="$app_profile_uuid" build && \


#进行签名，打成ipa包，并导出
/usr/bin/xcrun -sdk $sdk PackageApplication -v "$build_path" -o "$ipa_path" && \

rm -rf $build_directory 

# TODO: 上传到分发网站、 发邮件等等。。。