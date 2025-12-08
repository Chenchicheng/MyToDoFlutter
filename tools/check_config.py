#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查原数据库中的配置数据
"""

import sqlite3
import os
from datetime import datetime

def check_config():
    """检查原数据库中的配置"""
    print("=" * 50)
    print("  检查原数据库配置")
    print("=" * 50)
    print()
    
    # 获取用户目录
    user_home = os.path.expanduser("~")
    appdata_roaming = os.path.join(user_home, "AppData", "Roaming")
    
    # 可能的数据库位置
    possible_paths = [
        os.path.join(appdata_roaming, "todo-desktop-app", "todos.db"),
        os.path.join(appdata_roaming, "mytodo", "todos.db"),
    ]
    
    source_db_path = None
    for db_path in possible_paths:
        if os.path.exists(db_path):
            source_db_path = db_path
            print(f"✓ 找到原数据库: {db_path}\n")
            break
    
    if not source_db_path:
        print("❌ 找不到原数据库")
        return
    
    # 连接数据库
    conn = sqlite3.connect(source_db_path)
    cursor = conn.cursor()
    
    # 检查 todos 表数据
    cursor.execute("SELECT COUNT(*) FROM todos")
    todo_count = cursor.fetchone()[0]
    print(f"📝 任务总数: {todo_count}")
    
    # 检查完成状态
    cursor.execute("SELECT COUNT(*) FROM todos WHERE completed = 1")
    completed_count = cursor.fetchone()[0]
    print(f"✓ 已完成: {completed_count}")
    print(f"⏳ 待完成: {todo_count - completed_count}")
    print()
    
    # 检查 config 表
    try:
        cursor.execute("SELECT COUNT(*) FROM config")
        config_count = cursor.fetchone()[0]
        print(f"⚙️ 配置项总数: {config_count}\n")
        
        if config_count > 0:
            print("配置详情:")
            print("-" * 50)
            cursor.execute("SELECT key, value FROM config")
            configs = cursor.fetchall()
            
            for key, value in configs:
                # 隐藏敏感信息（API Key）
                if 'key' in key.lower() or 'password' in key.lower():
                    display_value = value[:10] + "..." if len(value) > 10 else "***"
                else:
                    display_value = value[:50] + "..." if len(value) > 50 else value
                
                print(f"  • {key}: {display_value}")
            print()
        else:
            print("⚠️ 配置表为空\n")
            
    except sqlite3.OperationalError:
        print("⚠️ config 表不存在\n")
    
    conn.close()
    
    # 检查目标数据库
    documents_path = os.path.join(user_home, "Documents")
    target_db_path = os.path.join(documents_path, "todos.db")
    
    if os.path.exists(target_db_path):
        print("=" * 50)
        print("  检查 Flutter 数据库")
        print("=" * 50)
        print()
        print(f"✓ Flutter 数据库: {target_db_path}\n")
        
        conn = sqlite3.connect(target_db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM todos")
        flutter_todo_count = cursor.fetchone()[0]
        print(f"📝 任务总数: {flutter_todo_count}")
        
        try:
            cursor.execute("SELECT COUNT(*) FROM config")
            flutter_config_count = cursor.fetchone()[0]
            print(f"⚙️ 配置项总数: {flutter_config_count}")
            
            if flutter_config_count > 0:
                print("\n配置详情:")
                print("-" * 50)
                cursor.execute("SELECT key, value FROM config")
                configs = cursor.fetchall()
                
                for key, value in configs:
                    # 隐藏敏感信息
                    if 'key' in key.lower() or 'password' in key.lower():
                        display_value = value[:10] + "..." if len(value) > 10 else "***"
                    else:
                        display_value = value[:50] + "..." if len(value) > 50 else value
                    
                    print(f"  • {key}: {display_value}")
            else:
                print("\n⚠️ Flutter 数据库的配置表为空")
                print("   需要重新运行迁移脚本！")
                
        except sqlite3.OperationalError:
            print("⚠️ config 表不存在")
        
        conn.close()
    else:
        print("⚠️ Flutter 数据库还不存在")
    
    print("\n" + "=" * 50)

if __name__ == "__main__":
    check_config()


