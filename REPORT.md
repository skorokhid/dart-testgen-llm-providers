# TestGen LLM Providers — Issue #29 Implementation Report

## Links
- **Original repository:** https://github.com/AmrAhmed119/dart-testgen
- **Fork repository:** https://github.com/skorokhid/dart-testgen-llm-providers
- **Issue:** https://github.com/AmrAhmed119/dart-testgen/issues/29

---

## Project Goal

Extend the `dart-testgen` tool with support for alternative LLM providers:
**OpenAI (ChatGPT)** and **Anthropic (Claude)**.

Previously the tool was tightly coupled to Google Gemini.

---

## Architectural Decision

Applied **Dependency Inversion Principle (SOLID)** — introduced `LLMProvider`
abstraction instead of direct dependency on the Gemini SDK.

### New Files

| File | Description |
|------|-------------|
| `lib/src/LLM/llm_provider.dart` | Abstract classes: `LLMProvider`, `LLMChat`, `ChatResponse` |
| `lib/src/LLM/gemini_provider.dart` | Refactored GeminiModel into an adapter |
| `lib/src/LLM/openai_provider.dart` | OpenAI ChatGPT API adapter |
| `lib/src/LLM/claude_provider.dart` | Anthropic Claude API adapter |
| `test/LLM/openai_provider_test.dart` | Unit tests for OpenAI adapter |
| `test/LLM/claude_provider_test.dart` | Unit tests for Claude adapter |

### Modified Files

| File | Change |
|------|--------|
| `lib/src/LLM/test_generator.dart` | `GeminiModel` → `LLMProvider` (DIP) |
| `bin/testgen.dart` | Added `--provider` CLI flag |
| `README.md` | Documentation for new providers |

---

## CLI Usage
```bash
# Gemini (default)
dart run bin/testgen.dart --provider gemini --api-key $GEMINI_API_KEY

# OpenAI
dart run bin/testgen.dart --provider openai --model gpt-4o-mini --api-key $OPENAI_API_KEY

# Claude
dart run bin/testgen.dart --provider claude --model claude-sonnet-4-6 --api-key $ANTHROPIC_API_KEY
```

---

## Test Results

| Provider | Status | Details |
|----------|--------|---------|
| Gemini | ✅ Fully working | Original functionality preserved |
| OpenAI | ✅ API connection verified | Rate limit on free tier |
| Claude | ✅ API connection verified | Requires account balance |

### Test Suite
- **Before changes:** 164/164 tests pass
- **After changes:** 173/173 tests pass (+9 new tests)
- **CI:** GitHub Actions — all tests green

---

## Bug Fixes in Original Repository

1. **Windows `\r\n` line endings** — `git config core.autocrlf false`
2. **Null URI in `target_files_test.dart`** — added `?.toString()` and `.cast<String>()`
3. **Missing `dart pub get` on CI** — added `setUpAll` to initialize test package

---

## Conclusion

Implemented a clean `LLMProvider` abstraction that makes it easy to add new
LLM providers in the future. All three providers implement the same interface
and handle API errors (rate limit, invalid key, overload).