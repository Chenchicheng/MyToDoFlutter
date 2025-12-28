# iOS 打包指南

本指南将帮助您在 Mac 上打包 Flutter 应用为 iOS 应用程序。

## 前置要求

1. ✅ **Flutter SDK** 已安装（已验证：Flutter 3.38.5）
2. ✅ **Xcode** 已安装（已验证：Xcode 26.1.1）
3. ✅ **Apple Developer 账号**（用于代码签名和分发）
4. ✅ **iOS 平台支持** 已启用

## 打包步骤

### 方法一：使用 Flutter 命令行（推荐用于开发测试）

#### 1. 构建 Release 版本

在项目根目录执行：

```bash
flutter build ios --release
```

这个命令会：
- 编译 Dart 代码为原生代码
- 构建 iOS 应用程序
- 优化性能并减小应用体积

#### 2. 查找生成的应用程序

构建完成后，应用程序位于：

```
build/ios/iphoneos/Runner.app
```

这是一个未签名的应用程序包，需要通过 Xcode 进行签名才能安装到设备。

### 方法二：使用 Xcode（用于代码签名和分发，推荐）

#### 1. 安装 CocoaPods 依赖

首次构建前，需要安装 iOS 依赖：

```bash
cd ios
pod install
cd ..
```

#### 2. 打开 Xcode 项目

**重要：** 必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj` 文件：

```bash
open ios/Runner.xcworkspace
```

#### 3. 配置签名和证书

1. 在 Xcode 中选择 `Runner` 项目（左侧项目导航器）
2. 选择 `Runner` target
3. 在 `Signing & Capabilities` 标签页中：
   - 勾选 `Automatically manage signing`
   - 选择您的开发团队（Apple ID）
   - 系统会自动创建或使用现有的 Bundle Identifier
   - 如果需要，可以修改 Bundle Identifier（例如：`com.yourcompany.myTodoFlutter`）

#### 4. 选择构建目标

在 Xcode 顶部工具栏：
- 选择目标设备：模拟器或连接的物理设备
- 选择构建配置：`Release` 用于发布版本

#### 5. 构建归档（Archive）

1. 在 Xcode 菜单栏选择：`Product` → `Archive`
2. 等待构建完成（可能需要几分钟）
3. 构建完成后，会自动打开 `Organizer` 窗口

#### 6. 分发应用

在 Organizer 窗口中：
1. 选择您刚创建的归档
2. 点击 `Distribute App` 按钮
3. 选择分发方式：
   - **App Store Connect**：上传到 App Store
   - **Ad Hoc**：分发给特定设备（需要注册设备 UDID）
   - **Development**：用于开发测试
   - **Enterprise**：企业内部分发（需要企业账号）

#### 7. 导出 IPA 文件

根据选择的分发方式：
- 选择导出选项（App Thinning、Bitcode 等）
- 选择签名方式（自动或手动）
- 点击 `Export` 导出 IPA 文件

## 应用配置

### 修改应用名称和 Bundle ID

#### 方法一：在 Xcode 中修改（推荐）

1. 打开 `ios/Runner.xcworkspace`
2. 选择 `Runner` target
3. 在 `General` 标签页中：
   - 修改 `Display Name`（应用显示名称）
   - 修改 `Bundle Identifier`（例如：`com.yourcompany.myTodoFlutter`）

#### 方法二：直接编辑配置文件

编辑 `ios/Runner/Info.plist`：

```xml
<key>CFBundleDisplayName</key>
<string>MyToDo</string>
```

### 修改应用图标

#### 方法一：使用 Xcode（推荐）

1. 打开 `ios/Runner.xcworkspace`
2. 在项目导航器中找到 `Assets.xcassets` → `AppIcon`
3. 将图标文件拖拽到对应的尺寸位置：
   - iPhone: 20pt, 29pt, 40pt, 60pt, 76pt, 83.5pt
   - iPad: 20pt, 29pt, 40pt, 76pt, 83.5pt
   - App Store: 1024pt

#### 方法二：手动替换图标文件

1. 准备图标文件（建议源文件尺寸：1024x1024 或更大）
2. 生成所有需要的尺寸（可以使用在线工具或脚本）
3. 替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 中的对应文件
4. 更新 `Contents.json` 文件

### 设置最低系统版本

编辑 `ios/Podfile`：

```ruby
platform :ios, '13.0'  # 推荐 iOS 13.0 或更高
```

然后运行：

```bash
cd ios
pod install
cd ..
```

### 配置网络权限（如果需要 HTTP）

如果您的应用需要访问 HTTP（非 HTTPS）接口，需要在 `Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**注意：** 建议使用 HTTPS，仅在必要时使用 HTTP。

## 常见问题

### 1. 构建失败：找不到证书

**解决方案：**
- 在 Xcode 中配置代码签名
- 确保已登录 Apple Developer 账号
- 检查证书是否有效

### 2. 构建失败：CocoaPods 错误

**解决方案：**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### 3. 无法安装到设备：签名错误

**解决方案：**
- 在 Xcode 中检查 `Signing & Capabilities`
- 确保设备已注册到开发者账号
- 检查 Bundle Identifier 是否唯一

### 4. 应用无法运行：权限问题

**解决方案：**
- 检查 `Info.plist` 中的权限配置
- 确保已添加必要的使用说明（如访问相册、位置等）

### 5. 网络请求失败（AI 功能）

**解决方案：**
- 检查 `Info.plist` 中的网络权限配置
- 确保已添加 `NSAppTransportSecurity` 配置（如需要）

### 6. 构建失败：Flutter 版本不兼容

**解决方案：**
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

## 分发应用

### 本地测试（Development）

1. 在 Xcode 中选择连接的设备
2. 点击运行按钮（▶️）或按 `Cmd + R`
3. 应用会直接安装到设备上

### TestFlight 分发（Beta 测试）

1. 在 Xcode 中创建 Archive
2. 选择 `Distribute App` → `App Store Connect`
3. 上传到 App Store Connect
4. 在 App Store Connect 中：
   - 选择构建版本
   - 添加测试用户
   - 提交审核（仅 TestFlight，不需要 App Store 审核）

### App Store 分发

1. 在 Xcode 中创建 Archive
2. 选择 `Distribute App` → `App Store Connect`
3. 上传到 App Store Connect
4. 在 App Store Connect 中：
   - 创建应用记录
   - 填写应用信息、截图、描述等
   - 提交审核

### Ad Hoc 分发（内部分发）

1. 在 Xcode 中创建 Archive
2. 选择 `Distribute App` → `Ad Hoc`
3. 选择要分发的设备（需要注册设备 UDID）
4. 导出 IPA 文件
5. 通过邮件或其他方式分发给用户

## 快速命令参考

```bash
# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 安装 iOS 依赖
cd ios && pod install && cd ..

# 构建 Release 版本
flutter build ios --release

# 构建并运行到设备
flutter run --release

# 打开 Xcode 项目
open ios/Runner.xcworkspace

# 查看连接的设备
flutter devices

# 查看构建信息
flutter build ios --release --verbose
```

## 设备 UDID 获取方法

### 方法一：通过 Xcode

1. 连接设备到 Mac
2. 打开 Xcode → `Window` → `Devices and Simulators`
3. 选择设备，查看 `Identifier`（即 UDID）

### 方法二：通过 iTunes（旧版本）

1. 连接设备到 Mac
2. 打开 iTunes
3. 点击设备图标
4. 在设备信息中查看 UDID

### 方法三：通过设备设置

1. 在设备上打开 `设置` → `通用` → `关于本机`
2. 找到 `标识符`（UDID）

## 下一步

- ✅ iOS 平台支持已创建
- 📦 配置应用图标和 Bundle ID
- 🔐 配置代码签名（用于分发）
- 🚀 准备发布到 App Store 或 TestFlight（可选）

---

**提示：** 
- 首次打包建议先在模拟器或真机上测试，确认应用正常运行后再进行代码签名和分发配置
- 如果只是本地测试，可以直接使用 `flutter run` 命令
- 发布到 App Store 需要完整的 Apple Developer 账号（年费 $99）

