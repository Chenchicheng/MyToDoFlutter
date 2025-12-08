import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// 数据迁移工具
/// 用于从原 Electron 桌面版迁移数据到 Flutter 版本
void main() async {
  print('==========================================');
  print('  Todo 数据迁移工具');
  print('  从原桌面版迁移数据到 Flutter 版本');
  print('==========================================\n');

  // 初始化 sqflite FFI
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  // 原数据库路径（Electron 应用数据目录）
  final sourceDbPaths = [
    r'C:\Users\kingsoft\AppData\Roaming\todo-desktop-app\todos.db',
    r'C:\Users\kingsoft\AppData\Roaming\mytodo\todos.db',
  ];

  // 找到存在的源数据库
  String? sourceDbPath;
  for (var dbPath in sourceDbPaths) {
    if (File(dbPath).existsSync()) {
      sourceDbPath = dbPath;
      print('✓ 找到原数据库: $dbPath');
      
      // 显示文件大小和修改时间
      final file = File(dbPath);
      final stat = file.statSync();
      print('  文件大小: ${(stat.size / 1024).toStringAsFixed(2)} KB');
      print('  修改时间: ${stat.modified}');
      break;
    }
  }

  if (sourceDbPath == null) {
    print('\n❌ 错误: 找不到原数据库文件');
    print('请确认以下路径是否存在:');
    for (var dbPath in sourceDbPaths) {
      print('  - $dbPath');
    }
    exit(1);
  }

  // 目标数据库路径（Flutter 应用）
  final documentsPath = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final targetDbPath = path.join(documentsPath, 'Documents', 'todos.db');
  
  print('\n✓ 目标数据库: $targetDbPath');

  try {
    // 打开源数据库
    print('\n[1/4] 正在打开源数据库...');
    final sourceDb = await databaseFactory.openDatabase(sourceDbPath, options: OpenDatabaseOptions(
      readOnly: true,
      singleInstance: false,
    ));
    
    // 读取所有数据
    print('[2/4] 正在读取原数据...');
    final todos = await sourceDb.query('todos', orderBy: 'id ASC');
    print('  → 找到 ${todos.length} 个任务');

    // 尝试读取配置表
    List<Map<String, dynamic>> configs = [];
    try {
      configs = await sourceDb.query('config');
      print('  → 找到 ${configs.length} 个配置项');
    } catch (e) {
      print('  → 配置表不存在或为空，跳过');
    }

    await sourceDb.close();

    // 打开或创建目标数据库
    print('[3/4] 正在准备目标数据库...');
    
    // 如果目标数据库已存在，先备份
    if (File(targetDbPath).existsSync()) {
      final backupPath = targetDbPath.replaceAll('.db', '_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      File(targetDbPath).copySync(backupPath);
      print('  → 已备份现有数据库到: $backupPath');
    }

    // 创建目录（如果不存在）
    final targetDir = Directory(path.dirname(targetDbPath));
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final targetDb = await databaseFactory.openDatabase(
      targetDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // 创建 todos 表
          await db.execute('''
            CREATE TABLE todos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              date TEXT,
              completed INTEGER DEFAULT 0,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
              task_type TEXT DEFAULT 'daily',
              period TEXT
            )
          ''');

          // 创建 config 表
          await db.execute('''
            CREATE TABLE config (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              key TEXT UNIQUE NOT NULL,
              value TEXT,
              updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // 创建索引
          await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_date ON todos(date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_task_type ON todos(task_type)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_period ON todos(period)');
        },
      ),
    );

    // 迁移数据
    print('[4/4] 正在迁移数据...');
    
    // 清空目标数据库（可选）
    await targetDb.delete('todos');
    await targetDb.delete('config');
    
    // 插入任务数据
    int successCount = 0;
    int errorCount = 0;
    
    for (var todo in todos) {
      try {
        await targetDb.insert('todos', {
          'id': todo['id'],
          'title': todo['title'],
          'description': todo['description'],
          'date': todo['date'],
          'completed': todo['completed'] ?? 0,
          'created_at': todo['created_at'],
          'task_type': todo['task_type'] ?? 'daily',
          'period': todo['period'],
        });
        successCount++;
      } catch (e) {
        print('  ✗ 迁移任务失败 (ID: ${todo['id']}): $e');
        errorCount++;
      }
    }
    
    print('  → 成功迁移 $successCount 个任务');
    if (errorCount > 0) {
      print('  ✗ 失败 $errorCount 个任务');
    }

    // 插入配置数据
    if (configs.isNotEmpty) {
      int configSuccessCount = 0;
      for (var config in configs) {
        try {
          await targetDb.insert('config', {
            'id': config['id'],
            'key': config['key'],
            'value': config['value'],
            'updated_at': config['updated_at'],
          });
          configSuccessCount++;
        } catch (e) {
          print('  ✗ 迁移配置失败 (${config['key']}): $e');
        }
      }
      print('  → 成功迁移 $configSuccessCount 个配置项');
    }

    await targetDb.close();

    // 统计信息
    print('\n==========================================');
    print('✓ 迁移完成！');
    print('==========================================');
    print('源数据库: $sourceDbPath');
    print('目标数据库: $targetDbPath');
    print('迁移任务数: $successCount');
    if (configs.isNotEmpty) {
      print('迁移配置数: ${configs.length}');
    }
    print('\n现在可以启动 Flutter 应用了！');
    
  } catch (e, stackTrace) {
    print('\n❌ 迁移过程中出错:');
    print(e);
    print('\n堆栈跟踪:');
    print(stackTrace);
    exit(1);
  }
}


