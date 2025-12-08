#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Todo 数据迁移工具
从原 Electron 桌面版迁移数据到 Flutter 版本
"""

import sqlite3
import os
import shutil
from datetime import datetime
from pathlib import Path

def print_header():
    """打印标题"""
    print("=" * 50)
    print("  Todo 数据迁移工具")
    print("  从原桌面版迁移数据到 Flutter 版本")
    print("=" * 50)
    print()

def find_source_database():
    """查找原数据库文件"""
    print("[1/5] 正在查找原数据库...")
    
    # 获取用户目录
    user_home = os.path.expanduser("~")
    appdata_roaming = os.path.join(user_home, "AppData", "Roaming")
    
    # 可能的数据库位置
    possible_paths = [
        os.path.join(appdata_roaming, "todo-desktop-app", "todos.db"),
        os.path.join(appdata_roaming, "mytodo", "todos.db"),
    ]
    
    for db_path in possible_paths:
        if os.path.exists(db_path):
            file_size = os.path.getsize(db_path) / 1024  # KB
            modified_time = datetime.fromtimestamp(os.path.getmtime(db_path))
            print(f"✓ 找到原数据库: {db_path}")
            print(f"  文件大小: {file_size:.2f} KB")
            print(f"  修改时间: {modified_time.strftime('%Y-%m-%d %H:%M:%S')}")
            return db_path
    
    print("\n❌ 错误: 找不到原数据库文件")
    print("请确认以下路径是否存在:")
    for db_path in possible_paths:
        print(f"  - {db_path}")
    return None

def get_target_database():
    """获取目标数据库路径"""
    print("\n[2/5] 确定目标数据库位置...")
    
    # Flutter 应用数据库位置（Documents 目录）
    user_home = os.path.expanduser("~")
    documents_path = os.path.join(user_home, "Documents")
    target_db_path = os.path.join(documents_path, "todos.db")
    
    print(f"✓ 目标数据库: {target_db_path}")
    
    # 确保 Documents 目录存在
    os.makedirs(documents_path, exist_ok=True)
    
    return target_db_path

def backup_existing_database(target_db_path):
    """备份现有数据库"""
    if os.path.exists(target_db_path):
        print("\n[3/5] 正在备份现有数据库...")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = target_db_path.replace(".db", f"_backup_{timestamp}.db")
        
        shutil.copy2(target_db_path, backup_path)
        print(f"✓ 已备份到: {backup_path}")
        
        # 删除旧数据库
        os.remove(target_db_path)
        print("✓ 已删除旧数据库")
    else:
        print("\n[3/5] 无需备份（目标数据库不存在）")

def read_source_data(source_db_path):
    """读取原数据库数据"""
    print("\n[4/5] 正在读取原数据...")
    
    conn = sqlite3.connect(source_db_path)
    cursor = conn.cursor()
    
    # 读取所有任务
    cursor.execute("SELECT * FROM todos ORDER BY id ASC")
    todos = cursor.fetchall()
    
    # 获取列名
    cursor.execute("PRAGMA table_info(todos)")
    todo_columns = [col[1] for col in cursor.fetchall()]
    
    print(f"  → 找到 {len(todos)} 个任务")
    
    # 尝试读取配置
    configs = []
    config_columns = []
    try:
        cursor.execute("SELECT * FROM config")
        configs = cursor.fetchall()
        
        cursor.execute("PRAGMA table_info(config)")
        config_columns = [col[1] for col in cursor.fetchall()]
        
        print(f"  → 找到 {len(configs)} 个配置项")
    except sqlite3.OperationalError:
        print("  → 配置表不存在或为空，跳过")
    
    conn.close()
    
    return {
        'todos': todos,
        'todo_columns': todo_columns,
        'configs': configs,
        'config_columns': config_columns
    }

def create_target_database(target_db_path, data):
    """创建目标数据库并迁移数据"""
    print("\n[5/5] 正在迁移数据到目标数据库...")
    
    conn = sqlite3.connect(target_db_path)
    cursor = conn.cursor()
    
    # 创建 todos 表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT,
            completed INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            task_type TEXT DEFAULT 'daily',
            period TEXT
        )
    ''')
    
    # 创建 config 表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE NOT NULL,
            value TEXT,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 创建索引
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_todos_date ON todos(date)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_todos_task_type ON todos(task_type)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_todos_period ON todos(period)')
    
    # 插入任务数据
    success_count = 0
    error_count = 0
    
    for todo in data['todos']:
        try:
            # 构建插入语句
            placeholders = ','.join(['?' for _ in data['todo_columns']])
            columns = ','.join(data['todo_columns'])
            
            cursor.execute(
                f"INSERT INTO todos ({columns}) VALUES ({placeholders})",
                todo
            )
            success_count += 1
        except Exception as e:
            print(f"  ✗ 迁移任务失败 (ID: {todo[0]}): {e}")
            error_count += 1
    
    print(f"  → 成功迁移 {success_count} 个任务")
    if error_count > 0:
        print(f"  ✗ 失败 {error_count} 个任务")
    
    # 插入配置数据
    if data['configs']:
        config_success_count = 0
        print("\n  正在迁移配置数据...")
        for config in data['configs']:
            try:
                # 获取配置的 key
                key_index = data['config_columns'].index('key')
                config_key = config[key_index]
                
                # 先检查配置是否已存在
                cursor.execute("SELECT id FROM config WHERE key = ?", (config_key,))
                existing = cursor.fetchone()
                
                if existing:
                    # 更新现有配置
                    value_index = data['config_columns'].index('value')
                    config_value = config[value_index]
                    cursor.execute(
                        "UPDATE config SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?",
                        (config_value, config_key)
                    )
                    print(f"  ✓ 更新配置: {config_key}")
                else:
                    # 插入新配置
                    placeholders = ','.join(['?' for _ in data['config_columns']])
                    columns = ','.join(data['config_columns'])
                    
                    cursor.execute(
                        f"INSERT INTO config ({columns}) VALUES ({placeholders})",
                        config
                    )
                    print(f"  ✓ 新增配置: {config_key}")
                
                config_success_count += 1
            except Exception as e:
                print(f"  ✗ 迁移配置失败: {e}")
        
        print(f"\n  → 成功迁移 {config_success_count} 个配置项")
    
    conn.commit()
    conn.close()
    
    return success_count, len(data['configs'])

def main():
    """主函数"""
    print_header()
    
    try:
        # 1. 查找原数据库
        source_db_path = find_source_database()
        if not source_db_path:
            return
        
        # 2. 确定目标数据库
        target_db_path = get_target_database()
        
        # 3. 备份现有数据库
        backup_existing_database(target_db_path)
        
        # 4. 读取原数据
        data = read_source_data(source_db_path)
        
        # 5. 创建目标数据库并迁移
        task_count, config_count = create_target_database(target_db_path, data)
        
        # 完成
        print("\n" + "=" * 50)
        print("✓ 迁移完成！")
        print("=" * 50)
        print(f"源数据库: {source_db_path}")
        print(f"目标数据库: {target_db_path}")
        print(f"迁移任务数: {task_count}")
        if config_count > 0:
            print(f"迁移配置数: {config_count}")
        print("\n现在可以启动 Flutter 应用了！")
        print("\n运行命令:")
        print("  cd E:\\MyToDoFlutter")
        print("  flutter run -d windows")
        
    except Exception as e:
        print(f"\n❌ 迁移过程中出错: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

