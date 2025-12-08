# MyToDo Flutter

基于 Flutter 的个人任务管理应用。

<img width="1264" height="681" alt="image" src="https://github.com/user-attachments/assets/4a205da1-a7c5-43c2-ae16-081d8a38eecc" />

<img width="1264" height="681" alt="image" src="https://github.com/user-attachments/assets/5066a096-0741-4523-8c23-03c6e524dc7e" />


## 功能特点

### 基础功能

- ✅ 本地 SQLite 数据库存储
- ✅ 跨平台桌面/移动应用（Windows、macOS、Linux、Android、iOS）
- ✅ 任务的增删改查
- ✅ 任务完成状态切换
- ✅ 按日期分组显示
- ✅ 任务统计功能
- ✅ 键盘快捷键支持
- ✅ Enter 键快速添加任务
- ✅ 深色/浅色主题切换
- ✅ 每日任务和阶段任务(周/月)管理

### AI 报告功能 🆕

- 🤖 **智能报告生成**: 接入大模型 API,自动分析任务生成工作报告
- 📅 **周报生成**: 自动统计本周工作并生成周报
- 📊 **月报生成**: 自动统计本月工作并生成月报
- 📈 **季度报生成**: 自动统计季度工作并生成季度总结
- 🔧 **自定义日期范围**: 支持任意时间段的报告生成
- ✍️ **自定义提示词**: 可自定义报告格式和内容要求
- 🔐 **多平台 API 支持**: 支持 OpenAI、DeepSeek、通义千问等多种大模型
- 💾 **本地安全存储**: API 密钥安全存储在本地 SQLite 数据库

## 项目结构

```
MyToDoFlutter/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   └── todo.dart
│   ├── database/                 # 数据库相关
│   │   └── database_helper.dart
│   ├── providers/               # 状态管理
│   │   ├── todo_provider.dart
│   │   ├── theme_provider.dart
│   │   └── config_provider.dart
│   ├── screens/                  # 页面
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   └── report_screen.dart
│   ├── widgets/                  # UI组件
│   │   ├── add_todo_widget.dart
│   │   ├── todo_list_widget.dart
│   │   ├── todo_item_widget.dart
│   │   └── stats_widget.dart
│   ├── services/                 # 服务层
│   │   └── ai_service.dart
│   └── utils/                    # 工具类
│       └── date_utils.dart
├── pubspec.yaml                  # 项目配置
└── README.md                     # 说明文档
```

## 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code（推荐）
- 各平台开发工具（根据目标平台选择）

## 安装和运行

### 1. 安装 Flutter

访问 [Flutter 官网](https://flutter.dev/docs/get-started/install) 下载并安装 Flutter SDK。

**⚠️ 如果遇到 `flutter` 命令无法识别的问题，请查看 [Flutter 环境配置指南.md](./Flutter环境配置指南.md)**

验证安装：

```bash
flutter doctor
```

### 2. 克隆或下载项目

```bash
cd E:\MyToDoFlutter
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 运行应用

#### 桌面平台（Windows/macOS/Linux）

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

#### 移动平台

```bash
# Android
flutter run -d android

# iOS (仅 macOS)
flutter run -d ios
```

### 5. 调试模式

在 VS Code 或 Android Studio 中打开项目，按 F5 启动调试。

## 数据存储

- **数据库位置**:

  - Windows: `%APPDATA%\com.example.my_todo_flutter\todos.db`
  - macOS: `~/Library/Application Support/com.example.my_todo_flutter/todos.db`
  - Linux: `~/.local/share/com.example.my_todo_flutter/todos.db`
  - Android: `/data/data/com.example.my_todo_flutter/databases/todos.db`
  - iOS: App 沙盒目录

- **数据库类型**: SQLite3

- **表结构**:

  ```sql
  -- 任务表
  CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      date TEXT,
      completed INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      task_type TEXT DEFAULT 'daily',
      period TEXT
  );

  -- 配置表（存储API密钥等配置）
  CREATE TABLE config (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  ```

## 构建发布版本

### Android APK

```bash
flutter build apk --release
```

生成的 APK 位于：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (AAB)

```bash
flutter build appbundle --release
```

生成的 AAB 位于：`build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

然后在 Xcode 中打开 `ios/Runner.xcworkspace` 进行签名和打包。

### Windows

```bash
flutter build windows --release
```

生成的可执行文件位于：`build/windows/runner/Release/`

### macOS

```bash
flutter build macos --release
```

生成的应用程序位于：`build/macos/Build/Products/Release/`

### Linux

```bash
flutter build linux --release
```

生成的可执行文件位于：`build/linux/x64/release/bundle/`

## 调试指南

### 1. 查看日志

运行应用时，终端会显示日志输出：

```bash
flutter run
```

### 2. 使用 Flutter DevTools

启动应用后，运行：

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 3. 常见问题排查

#### 数据库初始化失败

- 检查应用是否有文件系统写入权限
- 查看日志中的错误信息

#### AI 报告生成失败

- 检查网络连接
- 验证 API 密钥是否正确配置
- 查看设置页面中的 API 配置

#### 主题切换不生效

- 检查 `shared_preferences` 依赖是否正确安装
- 重启应用

### 4. 性能优化

- 使用分页加载大量任务
- 避免频繁的数据库查询
- 使用 `const` 构造函数优化 Widget 重建

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **sqflite**: SQLite 数据库操作
- **provider**: 状态管理
- **http**: HTTP 请求（用于 AI API）
- **intl**: 国际化支持
- **shared_preferences**: 本地配置存储

## 键盘快捷键

- `Enter`: 在任务输入框中按 Enter 键快速添加任务
- `Enter`: 在编辑框中按 Enter 键保存编辑
- `Escape`: 取消编辑

## AI 报告功能使用

### 快速开始

1. **配置 API**:

   - 点击主界面的"设置"按钮
   - 选择大模型提供商(OpenAI/DeepSeek/通义千问等)
   - 填入 API 密钥和相关配置
   - 测试连接确保配置正确

2. **生成报告**:
   - 点击主界面的"报告生成"按钮
   - 选择报告类型(周报/月报/季度报/自定义)
   - 点击"加载任务"按钮加载该时间段的任务
   - 点击"生成报告"按钮
   - 等待 AI 生成,然后复制使用

### 支持的大模型平台

- **OpenAI**: ChatGPT-3.5/4 系列
- **DeepSeek**: 高性价比国产大模型
- **通义千问**: 阿里云大模型服务
- **其他**: 任何兼容 OpenAI API 格式的服务

## 安全性

- ✅ API 密钥仅存储在本地 SQLite 数据库
- ✅ 不会上传到任何服务器
- ✅ 使用 Flutter 的安全存储机制
- ✅ 所有网络请求使用 HTTPS

## 许可证

MIT License

## 更新日志

### v1.0.0 (2025-01-XX)

- 初始版本发布
- 实现基础任务管理功能
- 实现 AI 报告生成功能
- 支持多平台部署
