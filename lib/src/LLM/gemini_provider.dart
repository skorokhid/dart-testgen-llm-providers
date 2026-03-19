import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';

/// Реалізація [LLMProvider] для Google Gemini API.
///
/// Використовує офіційний пакет [google_generative_ai].
/// Підтримує моделі: gemini-3-flash-preview, gemini-2.5-flash тощо.
class GeminiProvider implements LLMProvider {
  GeminiProvider({
    String modelName = 'gemini-3-flash-preview',
    String? apiKey,
    String systemInstruction =
        'You are a code assistant that generates Dart test '
        'cases based on provided code snippets.',
    int candidateCount = 1,
    double temperature = 0.2,
    double topP = 0.95,
  }) {
    final key = apiKey ?? _envApiKey();
    _model = _createModel(
      modelName: modelName,
      apiKey: key,
      systemInstruction: Content.system(systemInstruction),
      candidateCount: candidateCount,
      temperature: temperature,
      topP: topP,
    );
  }

  late final GenerativeModel _model;
  final _logger = Logger('GeminiProvider');

  String _envApiKey() {
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw StateError('Missing GEMINI_API_KEY environment variable.');
    }
    return apiKey;
  }

  GenerativeModel _createModel({
    required String modelName,
    required String apiKey,
    required Content systemInstruction,
    required int candidateCount,
    required double temperature,
    required double topP,
  }) {
    final schema = Schema.object(
      description: 'Schema for generated Dart test cases.',
      properties: {
        'code': Schema.string(
          description: 'Generated Dart test code.',
          nullable: false,
        ),
        'needTesting': Schema.boolean(
          description: 'True only if the code snippet can be usefully tested.',
          nullable: false,
        ),
      },
      requiredProperties: ['code', 'needTesting'],
    );

    _logger.info(
      'Creating Gemini model: $modelName, temperature: $temperature',
    );

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        candidateCount: candidateCount,
        temperature: temperature,
        topP: topP,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
  }

  @override
  GeminiChat startChat() {
    final chatSession = _model.startChat();
    return GeminiChat(chatSession);
  }

  @override
  Future<int> countTokens(LLMChat chat) async {
    if (chat is! GeminiChat) return 0;
    return _model
        .countTokens(chat.history)
        .then((r) => r.totalTokens)
        .catchError((_) => 0);
  }
}

/// Реалізація [LLMChat] для Gemini чат-сесії.
class GeminiChat implements LLMChat {
  GeminiChat(this._chat);

  final ChatSession _chat;

  Iterable<Content> get history => _chat.history;

  @override
  Future<ChatResponse> sendMessage(String content) async {
    final response = await _chat.sendMessage(Content.text(content));
    return _parseResponse(response);
  }

  ChatResponse _parseResponse(GenerateContentResponse response) {
    if (response.text == null) {
      throw FormatException('Gemini returned no text in response.');
    }
    return ChatResponse.fromJson(response.text!);
  }
}
