import 'package:intl/intl.dart';

class AppDateUtils {
  // 获取当前周（格式：2025-W03）
  static String getCurrentWeek() {
    final now = DateTime.now();
    final year = now.year;
    final weekNum = getWeekNumber(now);
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  // 获取周数（ISO 8601标准）
  static int getWeekNumber(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final jan4 = DateTime.utc(d.year, 1, 4);
    final jan4Day = jan4.weekday == 7 ? 1 : jan4.weekday + 1;
    final firstMonday = DateTime.utc(d.year, 1, 4 - jan4Day + 1);
    final diff = d.difference(firstMonday).inDays;
    return ((diff + jan4Day - 1) / 7).floor() + 1;
  }

  // 获取偏移后的周
  static String getWeekOffset(int offset) {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: offset * 7));
    final year = targetDate.year;
    final weekNum = getWeekNumber(targetDate);
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  // 获取当前月（格式：2025-01）
  static String getCurrentMonth() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  // 获取偏移后的月
  static String getMonthOffset(int offset) {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + offset, 1);
    final year = targetDate.year;
    final month = targetDate.month;
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  // 格式化日期显示
  static String formatDate(String dateStr) {
    if (dateStr.isEmpty) return '无日期';
    
    try {
      final date = DateTime.parse(dateStr);
      final weekday = getWeekday(date);
      final dateOnly = DateFormat('yyyy-MM-dd').format(date);
      
      return '$dateOnly $weekday';
    } catch (e) {
      return dateStr;
    }
  }

  // 获取周几的中文表示
  static String getWeekday(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.weekday % 7];
  }

  // 格式化阶段显示
  static String formatPeriod(String period, String type) {
    if (period.isEmpty || period == '未分类') return '未分类';

    if (type == 'weekly') {
      // 格式：2025-W03
      final parts = period.split('-W');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final week = int.tryParse(parts[1]);
        if (year != null && week != null) {
          final range = _getWeekDateRange(year, week);
          return '$year年 第$week周 (${range['start']}~${range['end']})';
        }
      }
    } else if (type == 'monthly') {
      // 格式：2025-01
      final parts = period.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) {
          return '$year年 $month月';
        }
      }
    }

    return period;
  }

  // 获取某周的起止日期
  static Map<String, String> _getWeekDateRange(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final jan4Day = jan4.weekday == 7 ? 1 : jan4.weekday + 1;
    final firstMonday = DateTime(year, 1, 4 - jan4Day + 1);
    final targetMonday = firstMonday.add(Duration(days: (week - 1) * 7));
    final targetSunday = targetMonday.add(const Duration(days: 6));

    return {
      'start': '${targetMonday.month}/${targetMonday.day}',
      'end': '${targetSunday.month}/${targetSunday.day}',
    };
  }
}

