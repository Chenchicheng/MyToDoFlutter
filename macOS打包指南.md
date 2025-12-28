# macOS 打包指南

本指南将帮助您在 Mac 上打包 Flutter 应用为 macOS 应用程序。

## 前置要求

1. ✅ **Flutter SDK** 已安装（已验证：Flutter 3.38.5）
2. ✅ **Xcode** 已安装（已验证：Xcode 26.1.1）
3. ✅ **macOS 平台支持** 已启用

## 打包步骤

### 方法一：使用 Flutter 命令行（推荐）

#### 1. 构建 Release 版本

在项目根目录执行：

```bash
flutter build macos --release
```

这个命令会：
- 编译 Dart 代码为原生代码
- 构建 macOS 应用程序包（.app）
- 优化性能并减小应用体积

#### 2. 查找生成的应用程序

构建完成后，应用程序位于：

```
build/macos/Build/Products/Release/my_todo_flutter.app
```

这是一个完整的 macOS 应用程序包，可以直接双击运行。

#### 3. 创建 DMG 安装包（可选）

如果您想创建一个更专业的安装包，可以使用以下方法：

**使用 create-dmg 工具：**

```bash
# 安装 create-dmg（如果未安装）
brew install create-dmg

# 创建 DMG
create-dmg \
  --volname "MyToDo Flutter" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "my_todo_flutter.app" 200 190 \
  --hide-extension "my_todo_flutter.app" \
  --app-drop-link 600 185 \
  "MyToDoFlutter-Installer.dmg" \
  "build/macos/Build/Products/Release/"
```

### 方法二：使用 Xcode（用于代码签名和分发）

#### 1. 打开 Xcode 项目

```bash
open macos/Runner.xcworkspace
```

#### 2. 配置签名和证书

1. 在 Xcode 中选择 `Runner` 项目
2. 选择 `Runner` target
3. 在 `Signing & Capabilities` 标签页中：
   - 选择您的开发团队（Apple ID）
   - 选择或创建 Bundle Identifier
   - 配置代码签名证书

#### 3. 构建归档

1. 在 Xcode 菜单栏选择：`Product` → `Archive`
2. 等待构建完成
3. 在 Organizer 窗口中：
   - 选择您的归档
   - 点击 `Distribute App`
   - 选择分发方式（App Store、Ad Hoc、Development 等）

## 应用配置

### 修改应用名称和 Bundle ID

编辑 `macos/Runner/Configs/AppInfo.xcconfig`：

```xcconfig
PRODUCT_NAME = MyToDo Flutter
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.myTodoFlutter
PRODUCT_COPYRIGHT = Copyright © 2025 Your Company. All rights reserved.
```

### 修改应用图标

#### 方法一：使用 Windows 图标自动转换（推荐）

项目已包含自动转换脚本，可以将 Windows 的 ICO 图标转换为 macOS 所需的 PNG 图标：

```bash
# 确保已安装 Pillow
pip3 install Pillow

# 运行转换脚本
python3 tools/convert_icon_macos.py
```

脚本会自动：
- 从 `windows/runner/resources/app_icon.ico` 读取图标
- 生成所有 macOS 需要的尺寸（16x16 到 1024x1024）
- 保存到 `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

#### 方法二：手动替换图标

1. 准备图标文件（建议源文件尺寸：1024x1024 或更大）
2. 生成以下尺寸的 PNG 图标：
   - `app_icon_16.png` (16x16)
   - `app_icon_32.png` (32x32)
   - `app_icon_64.png` (64x64)
   - `app_icon_128.png` (128x128)
   - `app_icon_256.png` (256x256)
   - `app_icon_512.png` (512x512)
   - `app_icon_1024.png` (1024x1024)
3. 替换 `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 中的对应文件
4. 确保所有图标都是 PNG 格式且尺寸正确

### 设置最低系统版本

编辑 `macos/Runner.xcodeproj/project.pbxproj` 或通过 Xcode 设置：
- 推荐最低版本：macOS 10.14 或更高

## 常见问题

### 1. 构建失败：找不到证书

**解决方案：**
- 在 Xcode 中配置代码签名
- 或者使用 `--no-codesign` 标志（仅用于测试）：
  ```bash
  flutter build macos --release --no-codesign
  ```

### 2. 应用无法运行：权限问题

**解决方案：**
- 首次运行时，在 `系统偏好设置` → `安全性与隐私` 中允许运行
- 或者使用代码签名（推荐）

### 3. 应用体积过大

**解决方案：**
- 确保使用 `--release` 标志
- 检查是否有未使用的资源文件
- 使用 `flutter build macos --release --split-debug-info=<directory>` 分离调试信息

### 4. 网络请求失败（AI 功能）

**解决方案：**
- 检查 `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements`
- 确保包含网络访问权限：
  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```

## 分发应用

### 本地分发

直接将 `.app` 文件或 DMG 分发给用户即可。

### App Store 分发

1. 在 Xcode 中完成代码签名
2. 创建归档并上传到 App Store Connect
3. 在 App Store Connect 中配置应用信息
4. 提交审核

### 公证（Notarization）

对于 macOS 10.15+，建议对应用进行公证：

```bash
# 使用 Xcode 的自动公证功能
# 或在 Xcode 中：Product → Archive → Distribute App → Developer ID
```

## 快速命令参考

```bash
# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 构建 Release 版本
flutter build macos --release

# 运行 Release 版本
open build/macos/Build/Products/Release/my_todo_flutter.app

# 查看构建信息
flutter build macos --release --verbose
```

## 下一步

- ✅ 应用已成功打包
- 📦 可以创建 DMG 安装包
- 🔐 配置代码签名（用于分发）
- 🚀 准备发布到 App Store（可选）

---

**提示：** 首次打包建议先使用 `flutter build macos --release` 测试，确认应用正常运行后再进行代码签名和分发配置。

