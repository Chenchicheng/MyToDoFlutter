// MyToDo Flutter 基础测试

import 'package:flutter_test/flutter_test.dart';
import 'package:my_todo_flutter/main.dart';

void main() {
  testWidgets('App should start', (WidgetTester tester) async {
    // 基础启动测试
    await tester.pumpWidget(const MyTodoApp());
    
    // 验证应用可以正常启动
    expect(find.text('MyToDo'), findsOneWidget);
  });
}
