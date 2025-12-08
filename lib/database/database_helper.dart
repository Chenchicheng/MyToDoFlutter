import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // 为桌面平台初始化 sqflite_ffi
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDB('todos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台使用 path_provider
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDir.path, filePath);
    } else {
      // 移动平台使用 getDatabasesPath
      dbPath = join(await getDatabasesPath(), filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // 确保表存在（兼容从原项目复制过来的数据库）
        await _ensureTablesExist(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 使用统一的方法创建表和索引
    await _ensureTablesExist(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 检查并添加新列（如果不存在）
    await _ensureTablesExist(db);
  }

  Future<void> _ensureTablesExist(Database db) async {
    // 创建表（如果不存在）
    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 检查并添加新列（如果不存在）
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(todos)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toList();

      if (!columnNames.contains('task_type')) {
        await db.execute('ALTER TABLE todos ADD COLUMN task_type TEXT DEFAULT \'daily\'');
      }

      if (!columnNames.contains('period')) {
        await db.execute('ALTER TABLE todos ADD COLUMN period TEXT');
      }
    } catch (e) {
      // 忽略列已存在的错误
    }

    // 创建索引（如果不存在）
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_date ON todos(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_task_type ON todos(task_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_period ON todos(period)');
    } catch (e) {
      // 忽略索引已存在的错误
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

