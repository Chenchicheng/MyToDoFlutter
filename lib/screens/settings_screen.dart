import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _apiKeyController;
  late TextEditingController _apiEndpointController;
  late TextEditingController _modelController;
  String _selectedProvider = 'openai';
  bool _isTesting = false;

  final Map<String, Map<String, String>> _presets = {
    'openai': {
      'endpoint': 'https://api.openai.com/v1/chat/completions',
      'model': 'gpt-3.5-turbo',
    },
    'deepseek': {
      'endpoint': 'https://api.deepseek.com/v1/chat/completions',
      'model': 'deepseek-chat',
    },
    'qwen': {
      'endpoint': 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      'model': 'qwen-turbo',
    },
  };

  @override
  void initState() {
    super.initState();
    final configProvider = context.read<ConfigProvider>();
    _apiKeyController = TextEditingController(text: configProvider.aiApiKey);
    _apiEndpointController = TextEditingController(text: configProvider.aiApiEndpoint);
    _modelController = TextEditingController(text: configProvider.aiModel);
    _selectedProvider = configProvider.aiProvider;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiEndpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _selectPreset(String preset) {
    setState(() {
      _selectedProvider = preset;
      if (_presets.containsKey(preset)) {
        _apiEndpointController.text = _presets[preset]!['endpoint']!;
        _modelController.text = _presets[preset]!['model']!;
      }
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final configProvider = context.read<ConfigProvider>();
    
    await configProvider.setConfig('ai_provider', _selectedProvider);
    await configProvider.setConfig('ai_api_key', _apiKeyController.text.trim());
    await configProvider.setConfig('ai_api_endpoint', _apiEndpointController.text.trim());
    await configProvider.setConfig('ai_model', _modelController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置保存成功！')),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写完整的API配置')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    // 临时保存配置用于测试
    final configProvider = context.read<ConfigProvider>();
    await configProvider.setConfig('ai_provider', _selectedProvider);
    await configProvider.setConfig('ai_api_key', _apiKeyController.text.trim());
    await configProvider.setConfig('ai_api_endpoint', _apiEndpointController.text.trim());
    await configProvider.setConfig('ai_model', _modelController.text.trim());

    try {
      final aiService = AIService(configProvider);
      final testTodos = [
        {
          'title': '测试任务',
          'description': '这是一个测试',
          'completed': 1,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }
      ];

      await aiService.generateReport(testTodos, 'weekly', '请简单回复"连接成功"即可。');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接测试成功！API配置正确。')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接测试失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'AI 服务配置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('预设配置'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPresetButton('openai', 'OpenAI'),
                _buildPresetButton('deepseek', 'DeepSeek'),
                _buildPresetButton('qwen', '通义千问'),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: '服务提供商',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek')),
                DropdownMenuItem(value: 'qwen', child: Text('通义千问')),
                DropdownMenuItem(value: 'custom', child: Text('自定义')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProvider = value!;
                  if (_presets.containsKey(value)) {
                    _apiEndpointController.text = _presets[value]!['endpoint']!;
                    _modelController.text = _presets[value]!['model']!;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '输入API密钥',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入API Key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiEndpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                hintText: '输入API端点地址',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入API Endpoint';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: '输入模型名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入Model';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('测试连接'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveConfig,
                    child: const Text('保存配置'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String preset, String label) {
    final isSelected = _selectedProvider == preset;
    return OutlinedButton(
      onPressed: () => _selectPreset(preset),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      child: Text(label),
    );
  }
}

