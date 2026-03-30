# TestGen LLM Providers — Звіт про виконання Issue #29

## Посилання
- **Оригінальний репозиторій:** https://github.com/AmrAhmed119/dart-testgen
- **Мій репозиторій:** https://github.com/skorokhid/dart-testgen-llm-providers
- **Issue:** https://github.com/AmrAhmed119/dart-testgen/issues/29

---

## Мета проєкту

Розширити інструмент `dart-testgen` підтримкою альтернативних LLM-провайдерів:
**OpenAI (ChatGPT)** та **Anthropic (Claude)**.

До змін інструмент був жорстко прив'язаний до Google Gemini.

---

## Архітектурне рішення

Застосовано принцип **Dependency Inversion (SOLID)** — введено абстракцію
`LLMProvider` замість прямої залежності від Gemini SDK.

### Нові файли

| Файл | Опис |
|------|------|
| `lib/src/LLM/llm_provider.dart` | Абстрактний клас `LLMProvider`, `LLMChat`, `ChatResponse` |
| `lib/src/LLM/gemini_provider.dart` | Рефакторинг GeminiModel у адаптер |
| `lib/src/LLM/openai_provider.dart` | Адаптер для OpenAI ChatGPT API |
| `lib/src/LLM/claude_provider.dart` | Адаптер для Anthropic Claude API |
| `test/LLM/openai_provider_test.dart` | Unit-тести для OpenAI адаптера |
| `test/LLM/claude_provider_test.dart` | Unit-тести для Claude адаптера |

### Змінені файли

| Файл | Зміна |
|------|-------|
| `lib/src/LLM/test_generator.dart` | `GeminiModel` → `LLMProvider` (DIP) |
| `bin/testgen.dart` | Додано `--provider` CLI прапор |
| `README.md` | Документація нових провайдерів |

---

## CLI використання
```bash
# Gemini (за замовчуванням)
dart run bin/testgen.dart --provider gemini --api-key $GEMINI_API_KEY

# OpenAI
dart run bin/testgen.dart --provider openai --model gpt-4o-mini --api-key $OPENAI_API_KEY

# Claude
dart run bin/testgen.dart --provider claude --model claude-sonnet-4-6 --api-key $ANTHROPIC_API_KEY
```

---

## Результати тестування

| Провайдер | Статус | Деталі |
|-----------|--------|--------|
| Gemini | ✅ Повністю працює | Оригінальна функціональність збережена |
| OpenAI | ✅ API підключення підтверджено | Rate limit на безкоштовному tier |
| Claude | ✅ API підключення підтверджено | Потребує балансу на акаунті |

### Тести
- **До змін:** 164/164 тестів проходять
- **Після змін:** 173/173 тестів проходять (+9 нових)
- **CI:** GitHub Actions — всі тести зелені

---

## Виправлені баги оригінального репозиторію

1. **Windows `\r\n` переноси рядків** — `git config core.autocrlf false`
2. **Null URI у `target_files_test.dart`** — додано `?.toString()` та `.cast<String>()`
3. **`dart pub get` на CI** — додано `setUpAll` для ініціалізації тестового пакету

---

## Висновок

Реалізовано повноцінну абстракцію `LLMProvider` що дозволяє легко додавати
нові LLM провайдери в майбутньому. Всі три провайдери реалізують єдиний
інтерфейс і обробляють помилки API (rate limit, invalid key, overload).