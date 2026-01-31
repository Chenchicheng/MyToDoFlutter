import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// 移动端添加任务对话框
/// 复用桌面端侧边栏的表单逻辑
class AddTodoDialog extends StatefulWidget {
  final String? initialTitle;
  final String initialTaskType;

  const AddTodoDialog({
    super.key,
    this.initialTitle,
    this.initialTaskType = 'daily',
  });

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _taskType;
  DateTime? _selectedDate;
  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _taskType = widget.initialTaskType;
    _selectedDate = DateTime.now();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  String _formatDateWithWeekday(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];
    return '${DateFormat('yyyy-MM-dd').format(date)} $weekday';
  }

  Future<void> _addTodo() async {
    if (!_formKey.currentState!.validate()) return;

    // 对于阶段任务，如果没有选择 period，使用默认值
    if (_taskType != 'daily' && _selectedPeriod == null) {
      _selectedPeriod = _taskType == 'weekly' ? _getCurrentWeek() : _getCurrentMonth();
    }

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

      if (mounted) {
        Navigator.pop(context);
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

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showTaskTypePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickerItem('每日任务', 'daily'),
            _buildPickerItem('每周任务', 'weekly'),
            _buildPickerItem('每月任务', 'monthly'),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _taskType = result;
        _updatePeriodOptions();
      });
    }
  }

  Future<void> _showPeriodPicker() async {
    final options = _taskType == 'weekly' ? _getWeekOptions() : _getMonthOptions();
    
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            String label;
            if (_taskType == 'weekly') {
              if (option == _getCurrentWeek()) {
                label = '当前周 ($option)';
              } else {
                final off = index - 1;
                label = off < 0 ? '前${-off}周 ($option)' : '后${off + 1}周 ($option)';
              }
            } else {
              if (option == _getCurrentMonth()) {
                label = '当前月 ($option)';
              } else {
                final off = index - 1;
                label = off < 0 ? '前${-off}月 ($option)' : '后${off + 1}月 ($option)';
              }
            }
            return _buildPickerItem(label, option);
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPeriod = result;
      });
    }
  }

  Widget _buildPickerItem(String label, String value) {
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏（只保留关闭按钮）
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 任务标题（多行输入）
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: '输入任务标题...',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: null,
                          minLines: 3,
                          textInputAction: TextInputAction.newline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入任务标题';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 任务类型
                        InkWell(
                          onTap: _showTaskTypePicker,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _taskType == 'daily'
                                      ? '每日任务'
                                      : (_taskType == 'weekly'
                                          ? '每周任务'
                                          : '每月任务'),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 日期或阶段选择
                        if (_taskType == 'daily')
                          InkWell(
                            onTap: _showDatePicker,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? _formatDateWithWeekday(_selectedDate!)
                                        : '选择日期',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: _showPeriodPicker,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedPeriod != null
                                          ? (_taskType == 'weekly'
                                              ? (_selectedPeriod == _getCurrentWeek()
                                                  ? '当前周 ($_selectedPeriod)'
                                                  : _selectedPeriod!)
                                              : (_selectedPeriod == _getCurrentMonth()
                                                  ? '当前月 ($_selectedPeriod)'
                                                  : _selectedPeriod!))
                                          : (_taskType == 'weekly'
                                              ? '请选择周次'
                                              : '请选择月份'),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: _selectedPeriod != null
                                                ? Theme.of(context).colorScheme.onSurface
                                                : Theme.of(context).hintColor,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // 添加按钮
                        ElevatedButton(
                          onPressed: _addTodo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('添加任务'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

