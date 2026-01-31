import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'celebration_overlay.dart';

class TodoItemWidget extends StatefulWidget {
  final Todo todo;

  const TodoItemWidget({
    super.key,
    required this.todo,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late String _taskType;
  late DateTime? _selectedDate;
  late String? _selectedPeriod;

  // 用于下拉菜单定位
  final GlobalKey _taskTypeKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();
  final GlobalKey _periodKey = GlobalKey();
  OverlayEntry? _calendarOverlay;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _taskType = widget.todo.taskType;
    _selectedDate = widget.todo.date != null 
        ? DateTime.tryParse(widget.todo.date!) 
        : DateTime.now();
    _selectedPeriod = widget.todo.period;
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
  }

  String _getCurrentWeek() {
    return app_date_utils.AppDateUtils.getCurrentWeek();
  }

  String _getCurrentMonth() {
    return app_date_utils.AppDateUtils.getCurrentMonth();
  }

  // 获取带周几的日期格式
  String _formatDateWithWeekday(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];
    return '${DateFormat('yyyy-MM-dd').format(date)} $weekday';
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

  void _showCalendarPicker() {
    _removeCalendarOverlay();
    
    final RenderBox renderBox = _dateKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final spaceBelow = screenHeight - offset.dy - size.height - 20;
    final calendarHeight = 280.0;
    final showAbove = spaceBelow < calendarHeight;
    
    final top = showAbove 
        ? offset.dy - calendarHeight - 4 
        : offset.dy + size.height + 4;

    _calendarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeCalendarOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
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
  }

  void _showTaskTypeMenu() {
    final RenderBox renderBox = _taskTypeKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final spaceBelow = screenHeight - offset.dy - size.height - 20;
    final menuHeight = 120.0;
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
          if (value == 'daily') {
            _selectedPeriod = null;
            _selectedDate ??= DateTime.now();
          } else {
            _selectedDate = null;
            _selectedPeriod = null;
          }
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
            label = off < 0 ? '前${-off}周 ($option)' : '后${off + 1}周 ($option)';
          }
        } else {
          if (option == _getCurrentMonth()) {
            label = '当前月 ($option)';
          } else {
            final index = options.indexOf(option);
            final off = index - 1;
            label = off < 0 ? '前${-off}月 ($option)' : '后${off + 1}月 ($option)';
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

  Future<void> _toggleComplete() async {
    // 记录切换前任务是否已完成
    final wasCompleted = widget.todo.isCompleted;
    
    final provider = context.read<TodoProvider>();
    await provider.toggleComplete(widget.todo.id!);
    
    // 只有从"未完成"变成"完成"时才显示全屏庆祝效果
    if (mounted && !wasCompleted) {
      CelebrationOverlay.show(context);
    }
  }

  Future<void> _deleteTodo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TodoProvider>();
      await provider.deleteTodo(widget.todo.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已删除')),
        );
      }
    }
  }

  Future<void> _saveEdit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务标题')),
      );
      return;
    }

    final provider = context.read<TodoProvider>();
    final dateStr = _taskType == 'daily' && _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    final success = await provider.updateTodo(
      id: widget.todo.id!,
      title: _titleController.text.trim(),
      date: dateStr,
      taskType: _taskType,
      period: _taskType != 'daily' ? _selectedPeriod : null,
    );

    if (mounted) {
      setState(() {
        _isEditing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已更新')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败')),
        );
      }
    }
  }

  void _cancelEdit() {
    _removeCalendarOverlay();
    setState(() {
      _isEditing = false;
      _titleController.text = widget.todo.title;
      _taskType = widget.todo.taskType;
      _selectedDate = widget.todo.date != null 
          ? DateTime.tryParse(widget.todo.date!) 
          : DateTime.now();
      _selectedPeriod = widget.todo.period;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditForm();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.todo.isCompleted 
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceVariant,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          // 复选框
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: widget.todo.isCompleted,
              onChanged: (_) => _toggleComplete(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          
          // 标题
          Expanded(
            child: Text(
              widget.todo.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: widget.todo.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                    color: widget.todo.isCompleted
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                  ),
            ),
          ),
          
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isEditing = true),
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    '编辑',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _deleteTodo,
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    '删除',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Colors.red[400],
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 任务标题
          TextField(
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
            autofocus: true,
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

          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('取消', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveEdit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('保存', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
