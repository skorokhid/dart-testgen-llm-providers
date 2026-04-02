import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';

class OpenAIProvider implements LLMProvider {
  OpenAIProvider({
    String modelName = 'gpt-4o-mini',
    String? apiKey,
    String systemInstruction =
        'You are a code assistant that generates Dart test '
        'cases based on provided code snippets.',
    double temperature = 0.2,
  }) : _modelName = modelName,
       _apiKey = apiKey ?? _envApiKey(),
       _systemInstruction = systemInstruction,
       _temperature = temperature;

  final String _modelName;
  final String _apiKey;
  final String _systemInstruction;
  final double _temperature;
  final _logger = Logger('OpenAIProvider');

  static String _envApiKey() {
    final apiKey = Platform.environment['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw StateError('Missing OPENAI_API_KEY environment variable.');
    }
    return apiKey;
  }

  @override
  OpenAIChat startChat() {
    _logger.info('Starting OpenAI chat session with model: $_modelName');
    return OpenAIChat(
      modelName: _modelName,
      apiKey: _apiKey,
      systemInstruction: _systemInstruction,
      temperature: _temperature,
    );
  }

  @override
  Future<int> countTokens(LLMChat chat) async {
    if (chat is! OpenAIChat) return 0;
    return chat.totalTokens;
  }
}


class OpenAIChat implements LLMChat {
  OpenAIChat({
    required String modelName,
    required String apiKey,
    required String systemInstruction,
    required double temperature,
  }) : _modelName = modelName,
       _apiKey = apiKey,
       _temperature = temperature,
       _messages = [
         {'role': 'system', 'content': systemInstruction},
       ];

  final String _modelName;
  final String _apiKey;
  final double _temperature;
  final List<Map<String, String>> _messages;
  final _logger = Logger('OpenAIChat');
  int _totalTokens = 0;

  int get totalTokens => _totalTokens;

  @override
  Future<ChatResponse> sendMessage(String content) async {
    _messages.add({'role': 'user', 'content': content});

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _modelName,
        'messages': _messages,
        'temperature': _temperature,
        'response_format': {'type': 'json_object'},
      }),
    );

    _logger.info('OpenAI response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw StateError('Invalid OpenAI API key.');
    }

    if (response.statusCode == 429) {
      throw StateError('OpenAI rate limit exceeded.');
    }

    if (response.statusCode != 200) {
      throw StateError(
        'OpenAI API error: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final usage = json['usage'] as Map<String, dynamic>?;
    _totalTokens += (usage?['total_tokens'] as int?) ?? 0;

    final assistantMessage =
        (json['choices'] as List).first['message']['content'] as String;

    _messages.add({'role': 'assistant', 'content': assistantMessage});

    return ChatResponse.fromJson(assistantMessage);
  }
}
