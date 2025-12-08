import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/config_provider.dart';

class AIService {
  final ConfigProvider configProvider;

  AIService(this.configProvider);

  Future<Map<String, dynamic>> callAI(
    List<Map<String, dynamic>> messages, {
    Function(String)? onProgress,
  }) async {
    final apiKey = configProvider.aiApiKey;
    final apiEndpoint = configProvider.aiApiEndpoint;
    final model = configProvider.aiModel;

    if (apiKey.isEmpty) {
      throw Exception('API密钥未配置，请先在设置中配置');
    }

    final requestBody = {
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
    };

    try {
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'API调用失败');
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] ?? '';

      return {
        'content': content,
        'usage': data['usage'],
      };
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  String cleanOutput(String content) {
    if (content.isEmpty) return '';

    // 去除Markdown格式符号
    String cleaned = content
        // 去除标题符号
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        // 去除粗体符号
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        // 去除斜体符号
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
        // 去除代码块符号
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // 去除列表符号（保留内容）
        .replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '')
        // 去除引用符号
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '')
        // 去除水平线
        .replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '')
        // 去除多余的换行（连续3个以上换行变为2个）
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // 去除首尾空白
        .trim();

    return cleaned;
  }

  Future<Map<String, dynamic>> generateReport(
    List<Map<String, dynamic>> todos,
    String reportType,
    String? customPrompt,
  ) async {
    if (todos.isEmpty) {
      return {'content': '该时间段内没有任务记录。'};
    }

    // 构建任务列表文本
    final taskList = todos.map((todo) {
      final status = (todo['completed'] as int? ?? 0) == 1 ? '✓' : '○';
      final date = todo['date'] as String? ?? '';
      final description = todo['description'] as String? ?? '';
      return '$status ${todo['title']}${date.isNotEmpty ? ' ($date)' : ''}${description.isNotEmpty ? ' - $description' : ''}';
    }).join('\n');

    // 默认提示词
    final defaultPrompts = {
      'weekly': '''我是一名职场人士，以下是我本周的工作任务记录，请帮我生成一份专业的周报。

任务列表（✓表示已完成，○表示未完成）：
$taskList

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出周报内容，使用中文，保持专业和简洁的语言风格。''',
      'monthly': '''我是一名职场人士，以下是我本月的工作任务记录，请帮我生成一份专业的月报。

任务列表（✓表示已完成，○表示未完成）：
$taskList

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出月报内容，使用中文，要求内容全面、有分析深度和战略思考。''',
      'quarterly': '''我是一名职场人士，以下是我本季度的工作任务记录，请帮我生成一份专业的季度总结报告。

任务列表（✓表示已完成，○表示未完成）：
$taskList

输出要求：
1、按照各todo的归属系统归类，目标类别、目标、权重占比、指标关键事项。一条一条列下来，总权重要等于100%；
2、输出尽量简洁，不要过分渲染；指标关键事项要按数字1、2、3等顺序展示
3、请使用纯文本格式输出，不要使用Markdown格式符号（如#、**、-、*等），直接输出文字内容即可

请直接输出季度报告内容，使用中文，要求内容全面、有分析深度和战略思考。''',
    };

    final prompt = customPrompt ?? 
        defaultPrompts[reportType] ?? 
        defaultPrompts['monthly']!;

    final messages = [
      {
        'role': 'system',
        'content': '你是一个专业的工作总结助手，擅长从任务记录中提炼关键信息，生成高质量的工作报告。请直接根据用户提供的任务列表生成报告，不要询问用户提供信息。输出时请使用纯文本格式，不要使用Markdown格式符号。',
      },
      {
        'role': 'user',
        'content': prompt,
      },
    ];

    final result = await callAI(messages.map((m) => m as Map<String, dynamic>).toList());

    // 清理输出内容
    if (result['content'] != null) {
      result['content'] = cleanOutput(result['content'] as String);
    }

    return result;
  }
}

