# 数据迁移工具使用说明

## 快速开始 🚀

### 方法 1: 使用批处理文件（最简单）

1. 双击运行项目根目录下的 `迁移数据.bat`
2. 等待迁移完成
3. 启动 Flutter 应用

### 方法 2: 使用 Python 脚本

```bash
cd E:\MyToDoFlutter\tools
python migrate_data.py
```

### 方法 3: 手动复制数据库

如果上述方法都不可行，可以手动复制：

```bash
# 找到原数据库（两个位置之一）
C:\Users\kingsoft\AppData\Roaming\todo-desktop-app\todos.db
C:\Users\kingsoft\AppData\Roaming\mytodo\todos.db

# 复制到 Flutter 数据库位置
C:\Users\kingsoft\Documents\todos.db
```

## 工具说明

### migrate_data.py

自动化数据迁移脚本，功能包括：

- ✅ 自动查找原数据库文件
- ✅ 备份现有 Flutter 数据库
- ✅ 迁移所有任务数据
- ✅ 迁移配置信息
- ✅ 创建必要的索引
- ✅ 显示详细的迁移过程

### 迁移内容

**任务数据 (todos 表):**
- 任务标题和描述
- 日期和阶段信息
- 完成状态
- 任务类型（每日/每周/每月）
- 创建时间

**配置数据 (config 表):**
- AI API 配置
- 应用设置

## 系统要求

- Python 3.6 或更高版本
- SQLite3（Python 自带）

## 常见问题

### Q: Python 未安装？
**A:** 下载并安装 Python:
1. 访问 https://www.python.org/downloads/
2. 下载最新版本
3. 安装时勾选 "Add Python to PATH"

### Q: 找不到原数据库？
**A:** 手动搜索:
1. 按 Win+R，输入 `%APPDATA%`
2. 搜索 `todos.db`
3. 找到最近修改的文件

### Q: 迁移失败？
**A:** 检查:
1. 原数据库文件是否可读
2. 目标目录是否有写权限
3. 查看错误信息进行针对性处理

## 验证迁移

启动 Flutter 应用后：

1. 检查任务总数是否正确（左侧边栏统计）
2. 浏览每日任务和阶段任务列表
3. 检查任务详情是否完整
4. 测试添加、编辑、删除功能

## 回滚

如果迁移后发现问题，可以恢复备份：

1. 找到备份文件（格式：`todos_backup_YYYYMMDD_HHMMSS.db`）
2. 复制到 `C:\Users\kingsoft\Documents\todos.db`
3. 重启应用

## 技术支持

如果遇到问题：
1. 查看 `数据迁移指南.md` 获取详细说明
2. 检查控制台输出的错误信息
3. 确认原数据库和目标数据库路径

---

**祝迁移顺利！** 🎉


