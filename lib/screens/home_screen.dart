import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/todo_list_widget.dart';
import '../widgets/sidebar_widget.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          // 判断是否需要响应式布局（可选）
          final useWideLayout = constraints.maxWidth >= 800;

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
                  color: Theme.of(context).colorScheme.background,
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
        },
      ),
    );
  }
}

