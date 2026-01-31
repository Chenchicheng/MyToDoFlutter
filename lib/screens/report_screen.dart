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
  String? _usedCustomPrompt;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _showReportPanel = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, 1);
    _endDate = today;
    // 设置默认提示词
    _updateDefaultPrompt();
  }

  // 获取默认提示词
  String _getDefaultPrompt(String reportType) {
    switch (reportType) {
      case 'weekly':
        return '''我是一名职场人士，以下是我本周的工作任务记录，请帮我生成一份专业的周报。

任务列表（✓表示已完成，○表示未完成）：
[任务列表将自动填充]

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出周报内容，使用中文，保持专业和简洁的语言风格。''';
      case 'monthly':
        return '''我是一名职场人士，以下是我本月的工作任务记录，请帮我生成一份专业的月报。

任务列表（✓表示已完成，○表示未完成）：
[任务列表将自动填充]

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出月报内容，使用中文，要求内容全面、有分析深度和战略思考。''';
      case 'quarterly':
        return '''我是一名职场人士，以下是我本季度的工作任务记录，请帮我生成一份专业的季度总结报告。

任务列表（✓表示已完成，○表示未完成）：
[任务列表将自动填充]

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出季度报告内容，使用中文，要求内容全面、有分析深度和战略思考。''';
      default:
        return '''我是一名职场人士，以下是我的工作任务记录，请帮我生成一份专业的报告。

任务列表（✓表示已完成，○表示未完成）：
[任务列表将自动填充]

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出月报内容，使用中文，要求内容全面、有分析深度和战略思考。''';
    }
  }

  // 更新默认提示词到输入框
  void _updateDefaultPrompt({bool forceUpdate = false}) {
    final defaultPrompt = _getDefaultPrompt(_reportType);
    final currentText = _customPromptController.text.trim();
    
    // 如果输入框为空，则设置默认提示词
    if (currentText.isEmpty) {
      _customPromptController.text = defaultPrompt;
      return;
    }
    
    // 如果强制更新，或者当前内容是之前类型的默认提示词，则更新
    if (forceUpdate) {
      _customPromptController.text = defaultPrompt;
      return;
    }
    
    // 检查当前内容是否是任何类型的默认提示词
    final isWeeklyDefault = currentText == _getDefaultPrompt('weekly');
    final isMonthlyDefault = currentText == _getDefaultPrompt('monthly');
    final isQuarterlyDefault = currentText == _getDefaultPrompt('quarterly');
    
    // 如果当前内容是默认提示词（任何类型），则更新为新类型的默认提示词
    if (isWeeklyDefault || isMonthlyDefault || isQuarterlyDefault) {
      _customPromptController.text = defaultPrompt;
    }
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
      _usedCustomPrompt = null;
      _showReportPanel = true; // 显示报告面板
    });

    try {
      final aiService = AIService(configProvider);
      // 获取当前输入框的内容
      final inputText = _customPromptController.text.trim();
      
      // 如果输入框为空，使用 null（AI 服务会使用默认提示词）
      if (inputText.isEmpty) {
        final result = await aiService.generateReport(
          _currentTodos.map((todo) => {
            'title': todo.title,
            'description': todo.description,
            'completed': todo.completed,
            'date': todo.date ?? todo.period ?? '',
          }).toList(),
          _reportType == 'custom' ? 'monthly' : _reportType,
          null, // 传递 null，使用 AI 服务的默认提示词
        );
        
        setState(() {
          _reportContent = result['content'] as String?;
          _usedCustomPrompt = null;
          _isGenerating = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('报告生成成功！')),
          );
        }
        return;
      }
      
      // 检查输入框内容是否是默认提示词（包含 [任务列表将自动填充]）
      final defaultPrompt = _getDefaultPrompt(_reportType == 'custom' ? 'monthly' : _reportType);
      final isDefaultPrompt = inputText == defaultPrompt;
      
      // 如果是默认提示词，传递 null 让 AI 服务使用真正的默认提示词（会替换任务列表）
      // 否则使用用户自定义的提示词
      final customPrompt = isDefaultPrompt ? null : inputText;

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
        _usedCustomPrompt = customPrompt;
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

  void _showFullScreenReport() {
    if (_reportContent == null || _reportContent!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            children: [
              // 顶部工具栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyReport,
                          tooltip: '复制',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: '关闭',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 报告内容
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 显示自定义提示词（如果有）
                        if (_usedCustomPrompt != null && _usedCustomPrompt!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '使用的自定义提示词：',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _usedCustomPrompt!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // 报告内容
                        SelectableText(
                          _reportContent!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.8,
                                letterSpacing: 0.3,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告生成'),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // 移动端：单列布局
            return _buildMobileLayout();
          } else {
            // 桌面端：双列布局
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧 - 配置和任务列表
        Expanded(
          flex: _showReportPanel ? 1 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: _showReportPanel
                  ? Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: _buildConfigPanel(),
          ),
        ),
        // 右侧 - 生成的报告（仅在显示时渲染）
        if (_showReportPanel)
          Expanded(
            flex: 1,
            child: _buildReportPanel(),
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildConfigPanel(),
        ),
        if (_showReportPanel) ...[
          const Divider(height: 1),
          Expanded(
            child: _buildReportPanel(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
    );
  }

  Widget _buildConfigPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    _buildSectionTitle('报告类型'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _reportType,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_view_week, size: 20),
                                SizedBox(width: 8),
                                Text('周报'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, size: 20),
                                SizedBox(width: 8),
                                Text('月报'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'quarterly',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_view_day, size: 20),
                                SizedBox(width: 8),
                                Text('季度报'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Row(
                              children: [
                                Icon(Icons.date_range, size: 20),
                                SizedBox(width: 8),
                                Text('自定义日期范围'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _reportType = value!;
                            // 更新默认提示词（如果当前是默认提示词，则切换为新类型的默认提示词）
                            _updateDefaultPrompt();
                          });
                        },
                      ),
                    ),
                    if (_reportType == 'custom') ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('日期范围'),
                      const SizedBox(height: 8),
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
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '开始日期',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _startDate != null
                                                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                                : '选择日期',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '结束日期',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _endDate != null
                                                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                                : '选择日期',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildSectionTitle('自定义提示词（可选）'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customPromptController,
                      decoration: InputDecoration(
                        hintText: '自定义提示词（留空使用默认提示词）',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadTasks,
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            label: Text(_isLoading ? '加载中...' : '加载任务'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating || _currentTodos.isEmpty
                                ? null
                                : _generateReport,
                            icon: _isGenerating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(_isGenerating ? '生成中...' : '生成报告'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentTodos.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '任务列表',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentTodos.length} 个',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._currentTodos.map((todo) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: todo.isCompleted
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  todo.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: todo.isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    todo.title,
                                    style: TextStyle(
                                      decoration: todo.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: todo.isCompleted
                                          ? Theme.of(context).colorScheme.outline
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }

  Widget _buildReportPanel() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                if (_reportContent != null)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _copyReport,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('复制'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showFullScreenReport(),
                        icon: const Icon(Icons.fullscreen, size: 18),
                        label: const Text(''),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '正在生成报告...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  )
                : _reportContent != null
                    ? Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _reportContent!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '报告将显示在这里',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '请先加载任务，然后点击"生成报告"',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
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

