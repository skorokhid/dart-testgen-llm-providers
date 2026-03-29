import 'package:test/test.dart';
import 'package:test_gen_ai/src/LLM/claude_provider.dart';
import 'package:test_gen_ai/src/LLM/llm_provider.dart';

void main() {
  group('ClaudeProvider', () {
    test('initializes correctly with provided apiKey', () {
      final provider = ClaudeProvider(apiKey: 'test-key');
      expect(provider, isA<LLMProvider>());
    });

    test('startChat returns ClaudeChat instance', () {
      final provider = ClaudeProvider(apiKey: 'test-key');
      final chat = provider.startChat();
      expect(chat, isA<ClaudeChat>());
    });

    test('countTokens returns 0 for non-ClaudeChat', () async {
      final provider = ClaudeProvider(apiKey: 'test-key');
      final chat = provider.startChat();
      final tokens = await provider.countTokens(chat);
      expect(tokens, equals(0));
    });
  });

  group('ClaudeChat', () {
    test('totalTokens starts at 0', () {
      final chat = ClaudeChat(
        modelName: 'claude-sonnet-4-6',
        apiKey: 'test-key',
        systemInstruction: 'test',
        temperature: 0.2,
        maxTokens: 1000,
      );
      expect(chat.totalTokens, equals(0));
    });
  });
}
