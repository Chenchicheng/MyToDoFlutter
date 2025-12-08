import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'todo_item_widget.dart';

class TodoListWidget extends StatelessWidget {
  final String taskType;

  const TodoListWidget({
    super.key,
    required this.taskType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final todos = taskType == 'daily' 
            ? provider.dailyTodos 
            : provider.periodTodos;
        final isLoading = provider.isLoading;

        if (isLoading && todos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (todos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                '暂无任务，添加一些任务开始吧！',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadTodos(reset: true),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: todos.length + 1,
            itemBuilder: (context, index) {
              if (index == todos.length) {
                // 加载更多按钮
                final hasMore = taskType == 'daily' 
                    ? provider.dailyTodos.length >= 20
                    : provider.periodTodos.length >= 20;
                
                if (!hasMore) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (taskType == 'daily') {
                          provider.loadMoreDailyTodos();
                        } else {
                          provider.loadMorePeriodTodos();
                        }
                      },
                      child: const Text('加载更多'),
                    ),
                  ),
                );
              }

              final todo = todos[index];
              final prevTodo = index > 0 ? todos[index - 1] : null;
              
              // 判断是否需要显示日期/阶段标题
              bool showHeader = false;
              if (taskType == 'daily') {
                final currentDate = todo.date ?? '';
                final prevDate = prevTodo?.date ?? '';
                showHeader = currentDate != prevDate;
              } else {
                final currentPeriod = todo.period ?? '';
                final prevPeriod = prevTodo?.period ?? '';
                showHeader = currentPeriod != prevPeriod;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader || index == 0)
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 8),
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        taskType == 'daily'
                            ? app_date_utils.AppDateUtils.formatDate(todo.date ?? '')
                            : app_date_utils.AppDateUtils.formatPeriod(todo.period ?? '', todo.taskType),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  if (showHeader || index == 0)
                    const SizedBox(height: 0)
                  else
                    const SizedBox(height: 0),
                  TodoItemWidget(todo: todo),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

