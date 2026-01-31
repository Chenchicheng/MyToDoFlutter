import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/todo_list_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/add_todo_dialog.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

// 业界标准断点定义
class Breakpoints {
  static const double mobile = 600;    // 手机
  static const double tablet = 900;    // 平板
  static const double desktop = 1200;  // 桌面
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 用于移动端的 Tab 切换

  @override
  void initState() {
    super.initState();
    // 加载任务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕宽度选择布局（业界标准响应式设计）
          if (constraints.maxWidth < Breakpoints.mobile) {
            return _buildMobileLayout();
          } else if (constraints.maxWidth < Breakpoints.tablet) {
            return _buildTabletLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  // 桌面端布局（macOS）- 原有布局保持不变
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左侧边栏
        SidebarWidget(
          onNavigateToReport: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportScreen()),
            );
          },
          onNavigateToSettings: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        // 右侧主内容区 - 两列显示
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                // 每日任务列
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Text(
                            '每日任务',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        const Expanded(
                          child: TodoListWidget(taskType: 'daily'),
                        ),
                      ],
                    ),
                  ),
                ),
                // 阶段任务列
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
                          ),
                          child: Text(
                            '阶段任务',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        const Expanded(
                          child: TodoListWidget(taskType: 'period'),
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
    );
  }

  // 平板端布局（中等屏幕）
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 侧边栏（较窄）
        SizedBox(
          width: 250,
          child: SidebarWidget(
            onNavigateToReport: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
            },
            onNavigateToSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ),
        // 单列任务列表（Tab 切换）
        Expanded(
          child: Column(
            children: [
              // Tab 切换
              Container(
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
                  children: [
                    Expanded(
                      child: _buildTabButton('每日任务', 0),
                    ),
                    Expanded(
                      child: _buildTabButton('阶段任务', 1),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: const [
                    TodoListWidget(taskType: 'daily'),
                    TodoListWidget(taskType: 'period'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 移动端布局（iOS 手机）
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // AppBar
        AppBar(
          title: const Text('MyToDo'),
          actions: [
            // 主题切换按钮
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                IconData iconData;
                String tooltip;
                switch (themeProvider.themeMode) {
                  case ThemeMode.system:
                    iconData = Icons.settings_brightness;
                    tooltip = '跟随系统';
                    break;
                  case ThemeMode.light:
                    iconData = Icons.light_mode;
                    tooltip = '亮色模式';
                    break;
                  case ThemeMode.dark:
                    iconData = Icons.dark_mode;
                    tooltip = '暗色模式';
                    break;
                }
                return IconButton(
                  icon: Icon(iconData),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: tooltip,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.assessment),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
              tooltip: '报告生成',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              tooltip: '设置',
            ),
          ],
        ),
        // Tab 切换
        Container(
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
            children: [
              Expanded(
                child: _buildTabButton('每日任务', 0),
              ),
              Expanded(
                child: _buildTabButton('阶段任务', 1),
              ),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: const [
              TodoListWidget(taskType: 'daily'),
              TodoListWidget(taskType: 'period'),
            ],
          ),
        ),
        // 底部添加任务快捷栏
        _buildMobileAddBar(),
      ],
    );
  }

  // Tab 按钮
  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  // 移动端底部添加任务栏
  Widget _buildMobileAddBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: () {
                _showAddTodoDialog(
                  initialTaskType: _selectedTabIndex == 0 ? 'daily' : 'period',
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  // 显示添加任务对话框
  void _showAddTodoDialog({
    String? initialTitle,
    String initialTaskType = 'daily',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTodoDialog(
        initialTitle: initialTitle,
        initialTaskType: initialTaskType,
      ),
    );
  }
}

