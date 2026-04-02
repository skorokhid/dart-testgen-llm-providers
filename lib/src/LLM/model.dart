import 'dart:io';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';

/// A wrapper around the Gemini [GenerativeModel] for creating, configuring,
/// and interacting with Gemini model.
class GeminiModel {
  GeminiModel({
    String modelName = 'gemini-3-flash-preview',
    String? apiKey,
    String systemInstruction =
        'You are a code assistant that generates Dart test '
        'cases based on provided code snippets.',
    int candidateCount = 1,
    double temperature = 0.2,
    double topP = 0.95,
  }) {
    _model = _createModel(
      modelName: modelName,
      apiKey: apiKey ?? _envApiKey(),
      systemInstruction: Content.system(systemInstruction),
      candidateCount: candidateCount,
      temperature: temperature,
      topP: topP,
    );
  }

  late final GenerativeModel _model;
  final _logger = Logger('GeminiModel');

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
          description:
              'True only if the code snippet can be usefully tested. '
              'False for trivial getters/setters, data classes, or asserts '
              'that do not make sense to test.',
          nullable: false,
        ),
      },
      requiredProperties: ['code', 'needTesting'],
    );

    _logger.info(
      'Creating Gemini model: $modelName, temperature: $temperature, '
      'topP: $topP, candidateCount: $candidateCount',
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

  /// Starts a new chat session with Gemini by creating a new [GeminiChat].
  GeminiChat startChat() {
    final chatSession = _model.startChat();
    return GeminiChat(chatSession);
  }

  /// Returns the total token count for the given [chat] history.
  ///
  /// If token counting fails (e.g., network error), this method returns `0`.
  Future<int> countTokens(GeminiChat chat) async => _model
      .countTokens(chat.history)
      .then((r) => r.totalTokens)
      .catchError((_) => 0);
}

/// A wrapper around the Gemini [ChatSession].
class GeminiChat {
  GeminiChat(this._chat);

  final ChatSession _chat;

  /// The full chat history for use with token counting or debugging.
  Iterable<Content> get history => _chat.history;

  /// Sends a new message to the model and returns the parsed [ChatResponse].
  Future<ChatResponse> sendMessage(String content) async {
    final response = await _chat.sendMessage(Content.text(content));
    return ChatResponse.fromJson(response.text ?? '');
  }
}

