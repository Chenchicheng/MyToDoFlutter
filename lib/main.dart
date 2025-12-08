import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/todo_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/config_provider.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 初始化数据库
    await DatabaseHelper.instance.database;
    debugPrint('数据库初始化成功');
  } catch (e) {
    debugPrint('数据库初始化失败: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
      ],
      child: MyTodoApp(),
    ),
  );
}

class MyTodoApp extends StatelessWidget {
  MyTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MyToDo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFF3498db), // 原项目的主色调
              brightness: Brightness.light,
              background: Color(0xFFF5F5F5),
              surface: Colors.white,
              surfaceVariant: Color(0xFFF8F9FA),
            ),
            useMaterial3: true,
            fontFamily: '-apple-system, BlinkMacSystemFont, Segoe UI, Roboto',
            dividerColor: Color(0xFFE0E0E0),
            scaffoldBackgroundColor: Color(0xFFF5F5F5),
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFF5a9fd4), // 深色模式的主色调
              brightness: Brightness.dark,
              background: Color(0xFF1a1a1a),
              surface: Color(0xFF2d2d2d),
              surfaceVariant: Color(0xFF404040),
            ),
            useMaterial3: true,
            fontFamily: '-apple-system, BlinkMacSystemFont, Segoe UI, Roboto',
            dividerColor: Color(0xFF404040),
            scaffoldBackgroundColor: Color(0xFF1a1a1a),
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: HomeScreen(),
        );
      },
    );
  }
}

