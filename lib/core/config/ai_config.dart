/// Configuration for the in-app AI assistant.
///
/// The API key is supplied ONLY at build/run time via
/// `--dart-define=AI_ASSISTANT_API_KEY=...` — it is deliberately NOT hard-coded,
/// so no secret ever lands in source control.
///
/// SECURITY: shipping a generative-AI key inside the app binary makes it
/// extractable. For production, proxy these calls through a backend (e.g. a
/// Supabase Edge Function) so the key never reaches the client at all.
abstract final class AiConfig {
  static const bool enabled = bool.fromEnvironment(
    'AI_ASSISTANT_ENABLED',
    defaultValue: true,
  );

  /// `gemini` (default) or an OpenAI-compatible API (`openai` / `grok` / `xai`).
  static const String provider = String.fromEnvironment(
    'AI_ASSISTANT_PROVIDER',
    defaultValue: 'gemini',
  );

  static const String model = String.fromEnvironment(
    'AI_ASSISTANT_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );

  static const String fallbackModel = String.fromEnvironment(
    'AI_ASSISTANT_FALLBACK_MODEL',
    defaultValue: 'gemini-flash-lite-latest',
  );

  static const String baseUrl = String.fromEnvironment(
    'AI_ASSISTANT_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );

  /// The API key, provided only via --dart-define (empty when not supplied).
  /// The assistant degrades gracefully to "unavailable" when this is empty.
  static String get apiKey =>
      const String.fromEnvironment('AI_ASSISTANT_API_KEY').trim();

  static bool get isOpenAiCompatible {
    final p = provider.toLowerCase();
    return p == 'openai' || p == 'grok' || p == 'xai';
  }

  /// Optional server proxy (the deployed web `/api/assistant`). When set, the
  /// app routes AI through the server so NO provider key ships in the binary —
  /// the recommended production setup. Supply via
  /// `--dart-define=AI_ASSISTANT_PROXY_URL=https://your-app.vercel.app/api/assistant`.
  static String get proxyUrl =>
      const String.fromEnvironment('AI_ASSISTANT_PROXY_URL').trim();

  /// True when a proxy endpoint is configured (preferred over an embedded key).
  static bool get useProxy => proxyUrl.isNotEmpty;
}
