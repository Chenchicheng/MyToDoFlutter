import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ConfigProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _aiProvider = 'openai';
  String _aiApiKey = '';
  String _aiApiEndpoint = 'https://api.openai.com/v1/chat/completions';
  String _aiModel = 'gpt-3.5-turbo';

  String get aiProvider => _aiProvider;
  String get aiApiKey => _aiApiKey;
  String get aiApiEndpoint => _aiApiEndpoint;
  String get aiModel => _aiModel;

  ConfigProvider() {
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      final db = await _dbHelper.database;
      final config = await db.query('config');
      
      final configMap = <String, String>{};
      for (var row in config) {
        configMap[row['key'] as String] = row['value'] as String? ?? '';
      }

      _aiProvider = configMap['ai_provider'] ?? 'openai';
      _aiApiKey = configMap['ai_api_key'] ?? '';
      _aiApiEndpoint = configMap['ai_api_endpoint'] ?? 'https://api.openai.com/v1/chat/completions';
      _aiModel = configMap['ai_model'] ?? 'gpt-3.5-turbo';

      notifyListeners();
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }
  }

  Future<bool> setConfig(String key, String value) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'config',
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 更新本地变量
      switch (key) {
        case 'ai_provider':
          _aiProvider = value;
          break;
        case 'ai_api_key':
          _aiApiKey = value;
          break;
        case 'ai_api_endpoint':
          _aiApiEndpoint = value;
          break;
        case 'ai_model':
          _aiModel = value;
          break;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('保存配置失败: $e');
      return false;
    }
  }

  Future<String?> getConfig(String key) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'config',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return result.first['value'] as String?;
    } catch (e) {
      debugPrint('获取配置失败: $e');
      return null;
    }
  }
}

