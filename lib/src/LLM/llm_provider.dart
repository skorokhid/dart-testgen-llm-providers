import 'dart:convert';

abstract class LLMProvider {
  LLMChat startChat();
  Future<int> countTokens(LLMChat chat);
}

abstract class LLMChat {
  Future<ChatResponse> sendMessage(String content);
}

class ChatResponse {
  ChatResponse({required this.code, required this.needTesting});

  final String code;
  final bool needTesting;

  factory ChatResponse.fromJson(String jsonText) {
    if (jsonText.isEmpty) {
      throw FormatException(
        'Model returned no text in GenerateContentResponse.',
      );
    }
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      return ChatResponse(
        code: json['code'] as String,
        needTesting: json['needTesting'] as bool,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse model response as JSON: $jsonText',
      );
    }
  }
}
