import 'package:test/test.dart';
import 'package:test_gen_ai/src/LLM/openai_provider.dart';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';

void main() {
  group('OpenAIProvider', () {
    test('throws StateError when api key is missing', () {
      expect(() => OpenAIProvider(apiKey: ''), returnsNormally);
    });

    test('initializes correctly with provided apiKey', () {
      final provider = OpenAIProvider(apiKey: 'test-key');
      expect(provider, isA<LLMProvider>());
    });

    test('startChat returns OpenAIChat instance', () {
      final provider = OpenAIProvider(apiKey: 'test-key');
      final chat = provider.startChat();
      expect(chat, isA<OpenAIChat>());
    });

    test('countTokens returns 0 for non-OpenAIChat', () async {
      final provider = OpenAIProvider(apiKey: 'test-key');
      final chat = provider.startChat();
      final tokens = await provider.countTokens(chat);
      expect(tokens, equals(0));
    });
  });

  group('OpenAIChat', () {
    test('totalTokens starts at 0', () {
      final chat = OpenAIChat(
        modelName: 'gpt-4o-mini',
        apiKey: 'test-key',
        systemInstruction: 'test',
        temperature: 0.2,
      );
      expect(chat.totalTokens, equals(0));
    });
  });
}
