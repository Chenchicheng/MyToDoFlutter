import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/todo.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Todo> _dailyTodos = [];
  List<Todo> _periodTodos = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'completed': 0,
    'pending': 0,
  };

  List<Todo> get dailyTodos => _dailyTodos;
  List<Todo> get periodTodos => _periodTodos;
  Map<String, dynamic> get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 分页相关
  int _dailyPage = 1;
  int _periodPage = 1;
  static const int pageSize = 20;
  bool _dailyHasMore = true;
  bool _periodHasMore = true;

  Future<void> loadTodos({bool reset = false}) async {
    if (reset) {
      _dailyPage = 1;
      _periodPage = 1;
      _dailyHasMore = true;
      _periodHasMore = true;
      _dailyTodos = [];
      _periodTodos = [];
    }

    await Future.wait([
      loadDailyTodosPage(_dailyPage, reset),
      loadPeriodTodosPage(_periodPage, reset),
    ]);
    
    await updateStats();
  }

  Future<void> loadDailyTodosPage(int page, bool isInitial) async {
    if (!_dailyHasMore && !isInitial) return;

    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final offset = (page - 1) * pageSize;
      
      final result = await db.query(
        'todos',
        where: 'task_type IS NULL OR task_type = ?',
        whereArgs: ['daily'],
        orderBy: 'date DESC, created_at DESC',
        limit: pageSize,
        offset: offset,
      );

      final todos = result.map((map) => Todo.fromMap(map)).toList();

      if (isInitial) {
        _dailyTodos = todos;
      } else {
        _dailyTodos.addAll(todos);
      }

      _dailyHasMore = todos.length == pageSize;
      _dailyPage = page;
    } catch (e) {
      debugPrint('加载每日任务失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPeriodTodosPage(int page, bool isInitial) async {
    if (!_periodHasMore && !isInitial) return;

    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final offset = (page - 1) * pageSize;
      
      // 获取周任务和月任务
      final weeklyResult = await db.query(
        'todos',
        where: 'task_type = ?',
        whereArgs: ['weekly'],
        orderBy: 'date DESC, created_at DESC',
        limit: pageSize,
        offset: offset,
      );

      final monthlyResult = await db.query(
        'todos',
        where: 'task_type = ?',
        whereArgs: ['monthly'],
        orderBy: 'date DESC, created_at DESC',
        limit: pageSize,
        offset: offset,
      );

      final weeklyTodos = weeklyResult.map((map) => Todo.fromMap(map)).toList();
      final monthlyTodos = monthlyResult.map((map) => Todo.fromMap(map)).toList();
      final allPeriodTodos = [...weeklyTodos, ...monthlyTodos];

      // 排序规则（参考原项目app.js）：
      // 1. 先按月份倒序（最新的月份在前）
      // 2. 同月份内，月任务排在周任务之前
      // 3. 同类型内，按period倒序
      allPeriodTodos.sort((a, b) {
        final monthA = _getPeriodMonth(a.period ?? '', a.taskType);
        final monthB = _getPeriodMonth(b.period ?? '', b.taskType);
        
        // 先按月份倒序
        if (monthA != monthB) {
          return monthB.compareTo(monthA);
        }
        
        // 同月份内，月任务排在周任务之前
        if (a.taskType == 'monthly' && b.taskType == 'weekly') {
          return -1;
        }
        if (a.taskType == 'weekly' && b.taskType == 'monthly') {
          return 1;
        }
        
        // 同类型内，按period倒序
        final periodA = a.period ?? '';
        final periodB = b.period ?? '';
        return periodB.compareTo(periodA);
      });

      if (isInitial) {
        _periodTodos = allPeriodTodos;
      } else {
        _periodTodos.addAll(allPeriodTodos);
      }

      _periodHasMore = weeklyTodos.length == pageSize || monthlyTodos.length == pageSize;
      _periodPage = page;
    } catch (e) {
      debugPrint('加载阶段任务失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreDailyTodos() async {
    if (!_dailyHasMore || _isLoading) return;
    await loadDailyTodosPage(_dailyPage + 1, false);
  }

  Future<void> loadMorePeriodTodos() async {
    if (!_periodHasMore || _isLoading) return;
    await loadPeriodTodosPage(_periodPage + 1, false);
  }

  Future<int> addTodo({
    required String title,
    String? description,
    String? date,
    String taskType = 'daily',
    String? period,
  }) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        'todos',
        {
          'title': title,
          'description': description,
          'date': date,
          'task_type': taskType,
          'period': period,
          'completed': 0,
        },
      );

      await loadTodos(reset: true);
      return id;
    } catch (e) {
      debugPrint('添加任务失败: $e');
      rethrow;
    }
  }

  Future<bool> updateTodo({
    required int id,
    required String title,
    String? description,
    String? date,
    String taskType = 'daily',
    String? period,
  }) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        'todos',
        {
          'title': title,
          'description': description,
          'date': date,
          'task_type': taskType,
          'period': period,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        await loadTodos(reset: true);
      }
      return count > 0;
    } catch (e) {
      debugPrint('更新任务失败: $e');
      return false;
    }
  }

  Future<bool> toggleComplete(int id) async {
    try {
      final db = await _dbHelper.database;
      
      // 获取当前状态
      final result = await db.query(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return false;

      final currentStatus = result.first['completed'] as int;
      final newStatus = currentStatus == 1 ? 0 : 1;

      final count = await db.update(
        'todos',
        {'completed': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        // 更新本地缓存
        _updateLocalTodoStatus(id, newStatus);
        await updateStats();
        notifyListeners();
      }

      return count > 0;
    } catch (e) {
      debugPrint('切换完成状态失败: $e');
      return false;
    }
  }

  void _updateLocalTodoStatus(int id, int status) {
    final todo = _dailyTodos.firstWhere(
      (t) => t.id == id,
      orElse: () => _periodTodos.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Todo not found'),
      ),
    );

    if (_dailyTodos.contains(todo)) {
      final index = _dailyTodos.indexOf(todo);
      _dailyTodos[index] = todo.copyWith(completed: status);
    } else {
      final index = _periodTodos.indexOf(todo);
      _periodTodos[index] = todo.copyWith(completed: status);
    }
  }

  Future<bool> deleteTodo(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        _dailyTodos.removeWhere((t) => t.id == id);
        _periodTodos.removeWhere((t) => t.id == id);
        await updateStats();
        notifyListeners();
      }

      return count > 0;
    } catch (e) {
      debugPrint('删除任务失败: $e');
      return false;
    }
  }

  Future<void> updateStats() async {
    try {
      final db = await _dbHelper.database;
      
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
      final completedResult = await db.rawQuery('SELECT COUNT(*) as count FROM todos WHERE completed = 1');
      
      _stats = {
        'total': totalResult.first['count'] as int,
        'completed': completedResult.first['count'] as int,
        'pending': (totalResult.first['count'] as int) - (completedResult.first['count'] as int),
      };
      
      notifyListeners();
    } catch (e) {
      debugPrint('更新统计失败: $e');
    }
  }

  Future<List<Todo>> getTodosByDateRange(String startDate, String endDate) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'todos',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date ASC, created_at ASC',
      );

      return result.map((map) => Todo.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取日期范围任务失败: $e');
      return [];
    }
  }

  Future<List<Todo>> getTodosByPeriod(String period) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'todos',
        where: 'period = ?',
        whereArgs: [period],
        orderBy: 'created_at ASC',
      );

      return result.map((map) => Todo.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取阶段任务失败: $e');
      return [];
    }
  }

  // 获取阶段所属的月份（格式：YYYY-MM）
  String _getPeriodMonth(String period, String type) {
    if (period.isEmpty || period == '未分类') return '0000-00';

    if (type == 'monthly') {
      // 月任务：period 本身就是月份格式 2025-01
      return period;
    } else if (type == 'weekly') {
      // 周任务：需要计算周的开始日期，然后提取月份
      // 格式：2025-W03
      final parts = period.split('-W');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final week = int.tryParse(parts[1]);
        if (year != null && week != null) {
          final weekStart = _getWeekStartDate(year, week);
          final month = weekStart.month.toString().padLeft(2, '0');
          return '$year-$month';
        }
      }
    }

    return '0000-00';
  }

  // 获取某周的开始日期
  DateTime _getWeekStartDate(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final jan4Day = jan4.weekday == 7 ? 1 : jan4.weekday + 1;
    final firstMonday = DateTime(year, 1, 4 - jan4Day + 1);
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }
}

