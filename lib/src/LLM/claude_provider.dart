import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';

/// Реалізація [LLMProvider] для Anthropic Claude API.
///
/// Використовує REST API endpoint: POST /v1/messages
/// Документація: https://docs.anthropic.com/en/api/messages
class ClaudeProvider implements LLMProvider {
  ClaudeProvider({
    String modelName = 'claude-sonnet-4-6',
    String? apiKey,
    String systemInstruction =
        'You are a code assistant that generates Dart test '
        'cases based on provided code snippets.',
    double temperature = 0.2,
    int maxTokens = 8096,
  }) : _modelName = modelName,
       _apiKey = apiKey ?? _envApiKey(),
       _systemInstruction = systemInstruction,
       _temperature = temperature,
       _maxTokens = maxTokens;

  final String _modelName;
  final String _apiKey;
  final String _systemInstruction;
  final double _temperature;
  final int _maxTokens;
  final _logger = Logger('ClaudeProvider');

  static String _envApiKey() {
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (apiKey == null) {
      throw StateError('Missing ANTHROPIC_API_KEY environment variable.');
    }
    return apiKey;
  }

  @override
  ClaudeChat startChat() {
    _logger.info('Starting Claude chat session with model: $_modelName');
    return ClaudeChat(
      modelName: _modelName,
      apiKey: _apiKey,
      systemInstruction: _systemInstruction,
      temperature: _temperature,
      maxTokens: _maxTokens,
    );
  }

  @override
  Future<int> countTokens(LLMChat chat) async {
    if (chat is! ClaudeChat) return 0;
    return chat.totalTokens;
  }
}

/// Реалізація [LLMChat] для Claude — зберігає історію розмови.
class ClaudeChat implements LLMChat {
  ClaudeChat({
    required String modelName,
    required String apiKey,
    required String systemInstruction,
    required double temperature,
    required int maxTokens,
  }) : _modelName = modelName,
       _apiKey = apiKey,
       _systemInstruction = systemInstruction,
       _temperature = temperature,
       _maxTokens = maxTokens,
       _messages = [];

  final String _modelName;
  final String _apiKey;
  final String _systemInstruction;
  final double _temperature;
  final int _maxTokens;
  final List<Map<String, String>> _messages;
  final _logger = Logger('ClaudeChat');
  int _totalTokens = 0;

  int get totalTokens => _totalTokens;

  @override
  Future<ChatResponse> sendMessage(String content) async {
    _messages.add({'role': 'user', 'content': content});

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _modelName,
        'max_tokens': _maxTokens,
        'system': _systemInstruction,
        'messages': _messages,
        'temperature': _temperature,
      }),
    );

    _logger.info('Claude response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw StateError('Invalid Anthropic API key.');
    }

    if (response.statusCode == 429) {
      throw StateError('Anthropic rate limit exceeded.');
    }

    if (response.statusCode == 529) {
      throw StateError('Anthropic API overloaded.');
    }

    if (response.statusCode != 200) {
      throw StateError(
        'Anthropic API error: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final usage = json['usage'] as Map<String, dynamic>?;
    _totalTokens +=
        ((usage?['input_tokens'] as int?) ?? 0) +
        ((usage?['output_tokens'] as int?) ?? 0);

    final assistantMessage = (json['content'] as List).first['text'] as String;

    _messages.add({'role': 'assistant', 'content': assistantMessage});

    return ChatResponse.fromJson(assistantMessage);
  }
}
