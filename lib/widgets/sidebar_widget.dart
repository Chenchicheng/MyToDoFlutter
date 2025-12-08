import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;

class SidebarWidget extends StatefulWidget {
  final VoidCallback onNavigateToReport;
  final VoidCallback onNavigateToSettings;

  const SidebarWidget({
    super.key,
    required this.onNavigateToReport,
    required this.onNavigateToSettings,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _taskType = 'daily';
  DateTime? _selectedDate;
  String? _selectedPeriod;
  
  // 用于下拉菜单定位
  final GlobalKey _taskTypeKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();
  final GlobalKey _periodKey = GlobalKey();
  bool _showCalendar = false;
  OverlayEntry? _calendarOverlay;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _removeCalendarOverlay();
    super.dispose();
  }

  void _removeCalendarOverlay() {
    _calendarOverlay?.remove();
    _calendarOverlay = null;
    _showCalendar = false;
  }

  void _showCalendarPicker() {
    _removeCalendarOverlay();
    
    final RenderBox renderBox = _dateKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 计算弹出位置，如果下方空间不够则向上弹出
    final spaceBelow = screenHeight - offset.dy - size.height - 20;
    final calendarHeight = 280.0;
    final showAbove = spaceBelow < calendarHeight;
    
    final top = showAbove 
        ? offset.dy - calendarHeight - 4 
        : offset.dy + size.height + 4;

    _calendarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeCalendarOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 日历弹出框 - 紧凑版
          Positioned(
            left: offset.dx,
            top: top,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: calendarHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.copyWith(
                      bodyMedium: const TextStyle(fontSize: 12),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _removeCalendarOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_calendarOverlay!);
    setState(() {
      _showCalendar = true;
    });
  }

  void _showTaskTypeMenu() {
    final RenderBox renderBox = _taskTypeKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 计算弹出位置
    final spaceBelow = screenHeight - offset.dy - size.height - 20;
    final menuHeight = 144.0; // 3项 * 48
    final showAbove = spaceBelow < menuHeight;

    showMenu<String>(
      context: context,
      color: Theme.of(context).colorScheme.surface,
      position: RelativeRect.fromLTRB(
        offset.dx,
        showAbove ? offset.dy - menuHeight : offset.dy + size.height,
        offset.dx + size.width,
        showAbove ? offset.dy : offset.dy + size.height + menuHeight,
      ),
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
      ),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        PopupMenuItem(value: 'daily', height: 40, child: Text('每日任务', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
        PopupMenuItem(value: 'weekly', height: 40, child: Text('每周任务', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
        PopupMenuItem(value: 'monthly', height: 40, child: Text('每月任务', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _taskType = value;
          _updatePeriodOptions();
        });
      }
    });
  }

  void _showPeriodMenu() {
    final RenderBox renderBox = _periodKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    final options = _taskType == 'weekly' ? _getWeekOptions() : _getMonthOptions();
    
    // 计算弹出位置
    final spaceBelow = screenHeight - offset.dy - size.height - 20;
    final menuHeight = options.length * 40.0;
    final showAbove = spaceBelow < menuHeight;
    
    showMenu<String>(
      context: context,
      color: Theme.of(context).colorScheme.surface,
      position: RelativeRect.fromLTRB(
        offset.dx,
        showAbove ? offset.dy - menuHeight : offset.dy + size.height,
        offset.dx + size.width,
        showAbove ? offset.dy : offset.dy + size.height + menuHeight,
      ),
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
      ),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: options.map((option) {
        String label;
        if (_taskType == 'weekly') {
          if (option == _getCurrentWeek()) {
            label = '当前周 ($option)';
          } else {
            final index = options.indexOf(option);
            final off = index - 1;
            label = off < 0 ? '前${-off}周 ($option)' : '后$off周 ($option)';
          }
        } else {
          if (option == _getCurrentMonth()) {
            label = '当前月 ($option)';
          } else {
            final index = options.indexOf(option);
            final off = index - 1;
            label = off < 0 ? '前${-off}月 ($option)' : '后$off月 ($option)';
          }
        }
        return PopupMenuItem(value: option, height: 40, child: Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)));
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedPeriod = value;
        });
      }
    });
  }

  void _updatePeriodOptions() {
    setState(() {
      _selectedPeriod = null;
    });
  }

  String _getCurrentWeek() {
    return app_date_utils.AppDateUtils.getCurrentWeek();
  }

  String _getCurrentMonth() {
    return app_date_utils.AppDateUtils.getCurrentMonth();
  }

  List<String> _getWeekOptions() {
    final options = <String>[];
    final currentWeek = _getCurrentWeek();
    options.add(currentWeek);
    
    for (int i = -2; i <= 2; i++) {
      if (i != 0) {
        options.add(app_date_utils.AppDateUtils.getWeekOffset(i));
      }
    }
    return options;
  }

  List<String> _getMonthOptions() {
    final options = <String>[];
    final currentMonth = _getCurrentMonth();
    options.add(currentMonth);
    
    for (int i = -2; i <= 2; i++) {
      if (i != 0) {
        options.add(app_date_utils.AppDateUtils.getMonthOffset(i));
      }
    }
    return options;
  }

  Future<void> _addTodo() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TodoProvider>();
    final dateStr = _taskType == 'daily' 
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    try {
      await provider.addTodo(
        title: _titleController.text.trim(),
        date: dateStr,
        taskType: _taskType,
        period: _taskType != 'daily' ? _selectedPeriod : null,
      );

      _titleController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedPeriod = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务添加成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  // 获取带周几的日期格式
  String _formatDateWithWeekday(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];
    return '${DateFormat('yyyy-MM-dd').format(date)} $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final todoProvider = context.watch<TodoProvider>();
    final stats = todoProvider.stats;
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  'MyToDo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 主题切换按钮
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surfaceVariant : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '主题',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => themeProvider.toggleTheme(),
                        child: Container(
                          width: 60,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                left: themeProvider.themeMode == ThemeMode.dark ? 32 : 2,
                                top: 2,
                                child: Container(
                                  width: 24,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: themeProvider.themeMode == ThemeMode.dark
                                        ? Colors.grey[600]
                                        : Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      themeProvider.themeMode == ThemeMode.dark
                                          ? Icons.nightlight_round
                                          : Icons.wb_sunny,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 导航菜单
                _buildNavButton(
                  icon: Icons.assessment,
                  label: '报告生成',
                  onTap: widget.onNavigateToReport,
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  icon: Icons.settings,
                  label: '设置',
                  onTap: widget.onNavigateToSettings,
                ),
              ],
            ),
          ),
          
          // 中间占位（弹性空间）
          const Spacer(),

          // 添加任务表单（底部）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 任务标题
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '输入任务标题...',
                      hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入任务标题';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _addTodo(),
                  ),
                  const SizedBox(height: 12),

                  // 任务类型 - 自定义下拉
                  InkWell(
                    key: _taskTypeKey,
                    onTap: _showTaskTypeMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _taskType == 'daily' ? '每日任务' : (_taskType == 'weekly' ? '每周任务' : '每月任务'),
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 日期或阶段选择
                  if (_taskType == 'daily')
                    InkWell(
                      key: _dateKey,
                      onTap: _showCalendarPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? _formatDateWithWeekday(_selectedDate!)
                                  : '选择日期',
                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    )
                  else
                    InkWell(
                      key: _periodKey,
                      onTap: _showPeriodMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedPeriod != null
                                  ? (_taskType == 'weekly' 
                                      ? (_selectedPeriod == _getCurrentWeek() ? '当前周 ($_selectedPeriod)' : _selectedPeriod!)
                                      : (_selectedPeriod == _getCurrentMonth() ? '当前月 ($_selectedPeriod)' : _selectedPeriod!))
                                  : (_taskType == 'weekly' ? '请选择周次' : '请选择月份'),
                              style: TextStyle(
                                fontSize: _selectedPeriod != null ? 14 : 13,
                                color: _selectedPeriod != null 
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).hintColor,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 添加按钮
                  ElevatedButton(
                    onPressed: _addTodo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('添加任务'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 统计信息
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surfaceVariant : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow('总任务', stats['total'].toString()),
                  const SizedBox(height: 4),
                  _buildStatRow('已完成', stats['completed'].toString()),
                  const SizedBox(height: 4),
                  _buildStatRow('待完成', stats['pending'].toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().themeMode == ThemeMode.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surfaceVariant : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}

