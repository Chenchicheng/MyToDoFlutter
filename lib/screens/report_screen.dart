import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../providers/config_provider.dart';
import '../services/ai_service.dart';
import '../models/todo.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _reportType = 'weekly';
  DateTime? _startDate;
  DateTime? _endDate;
  final _customPromptController = TextEditingController();
  List<Todo> _currentTodos = [];
  String? _reportContent;
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, 1);
    _endDate = today;
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  Map<String, DateTime> _getDateRange() {
    final today = DateTime.now();
    
    switch (_reportType) {
      case 'weekly':
        // 本周（周一到周日）
        final dayOfWeek = today.weekday;
        final diffToMonday = dayOfWeek == 7 ? -6 : 1 - dayOfWeek;
        final startDate = today.add(Duration(days: diffToMonday));
        final endDate = startDate.add(const Duration(days: 6));
        return {'start': startDate, 'end': endDate};
      
      case 'monthly':
        // 本月
        final startDate = DateTime(today.year, today.month, 1);
        final endDate = DateTime(today.year, today.month + 1, 0);
        return {'start': startDate, 'end': endDate};
      
      case 'quarterly':
        // 本季度
        final quarter = (today.month - 1) ~/ 3;
        final startDate = DateTime(today.year, quarter * 3 + 1, 1);
        final endDate = DateTime(today.year, quarter * 3 + 4, 0);
        return {'start': startDate, 'end': endDate};
      
      default:
        return {
          'start': _startDate ?? today,
          'end': _endDate ?? today,
        };
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _currentTodos = [];
    });

    try {
      final range = _getDateRange();
      final startStr = DateFormat('yyyy-MM-dd').format(range['start']!);
      final endStr = DateFormat('yyyy-MM-dd').format(range['end']!);

      final provider = context.read<TodoProvider>();
      final todos = await provider.getTodosByDateRange(startStr, endStr);

      setState(() {
        _currentTodos = todos;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功加载 ${todos.length} 个任务'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载任务失败: $e')),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (_currentTodos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的任务数据')),
      );
      return;
    }

    final configProvider = context.read<ConfigProvider>();
    if (configProvider.aiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置页面配置大模型API')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _reportContent = null;
    });

    try {
      final aiService = AIService(configProvider);
      final customPrompt = _customPromptController.text.trim().isEmpty
          ? null
          : _customPromptController.text.trim();

      final todosMap = _currentTodos.map((todo) => {
        'title': todo.title,
        'description': todo.description,
        'completed': todo.completed,
        'date': todo.date ?? todo.period ?? '',
      }).toList();

      final result = await aiService.generateReport(
        todosMap,
        _reportType == 'custom' ? 'monthly' : _reportType,
        customPrompt,
      );

      setState(() {
        _reportContent = result['content'] as String?;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告生成成功！')),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成报告失败: $e')),
        );
      }
    }
  }

  Future<void> _copyReport() async {
    if (_reportContent == null || _reportContent!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可复制的报告内容')),
      );
      return;
    }

    // 这里需要使用 clipboard 包，暂时简化处理
    // 实际项目中可以添加 clipboard 依赖
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告内容已准备，请手动复制')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告生成'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 - 配置和任务列表
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '报告配置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _reportType,
                      decoration: const InputDecoration(
                        labelText: '报告类型',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('周报')),
                        DropdownMenuItem(value: 'monthly', child: Text('月报')),
                        DropdownMenuItem(value: 'quarterly', child: Text('季度报')),
                        DropdownMenuItem(value: 'custom', child: Text('自定义日期范围')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _reportType = value!;
                        });
                      },
                    ),
                    if (_reportType == 'custom') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '开始日期',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                      : '选择日期',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '结束日期',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                      : '选择日期',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customPromptController,
                      decoration: const InputDecoration(
                        labelText: '自定义提示词（可选）',
                        hintText: '留空使用默认提示词',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loadTasks,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('加载任务'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isGenerating || _currentTodos.isEmpty
                                ? null
                                : _generateReport,
                            child: _isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('生成报告'),
                          ),
                        ),
                      ],
                    ),
                    if (_currentTodos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        '任务列表 (${_currentTodos.length}个)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ..._currentTodos.map((todo) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: todo.isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    todo.title,
                                    style: TextStyle(
                                      decoration: todo.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: todo.isCompleted
                                          ? Theme.of(context).colorScheme.outline
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 右侧 - 生成的报告
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '生成的报告',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        if (_reportContent != null)
                          TextButton.icon(
                            onPressed: _copyReport,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isGenerating
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('正在生成报告...'),
                              ],
                            ),
                          )
                        : _reportContent != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  _reportContent!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '报告将显示在这里',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '请先加载任务，然后点击"生成报告"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

