import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../../core/config/ai_config.dart';
import '../../domain/entities/chat_message.dart';
import 'assistant_remote_datasource.dart';

/// Routes the assistant through the deployed web `/api/assistant` proxy so the
/// provider key never ships in the app binary. The server builds the system
/// prompt for the "app" surface and injects the [context] hint; the app only
/// sends the conversation. Mirrors the web `use-assistant.ts` request shape.
class AssistantProxyDataSourceImpl implements AssistantRemoteDataSource {
  final http.Client client;
  AssistantProxyDataSourceImpl({required this.client});

  static const String _feature = 'Assistant';

  @override
  Future<String> generateReply({
    required String systemPrompt, // built server-side for the "app" surface
    required List<ChatMessage> history,
    String? context,
    String? languageCode,
    String? userName,
  }) async {
    final url = AiConfig.proxyUrl;
    if (url.isEmpty) {
      throw AssistantApiException(
        AssistantApiErrorType.config,
        'No assistant proxy URL configured',
      );
    }

    final messages = history
        .where((m) => m.text.trim().isNotEmpty)
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'text': m.text,
          },
        )
        .toList();

    final body = <String, dynamic>{
      'surface': 'app',
      'locale': (languageCode == null || languageCode.trim().isEmpty)
          ? 'en'
          : languageCode.trim(),
      'messages': messages,
      if (userName != null && userName.trim().isNotEmpty)
        'userName': userName.trim(),
      if (context != null && context.trim().isNotEmpty)
        'context': context.trim(),
    };

    late final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      developer.log('[Assistant] Proxy network error: $error', name: _feature);
      throw AssistantApiException(
        AssistantApiErrorType.network,
        error.toString(),
      );
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = const <String, dynamic>{};
    }

    // The server normalises failures into an `error` kind (a safe refusal comes
    // back as "blocked" with HTTP 200), so check that first regardless of status.
    final error = data['error'] as String?;
    if (error != null) {
      throw AssistantApiException(_mapError(error, response.statusCode), error);
    }

    if (response.statusCode == 200) {
      final reply = (data['reply'] as String?)?.trim() ?? '';
      if (reply.isEmpty) {
        throw AssistantApiException(
          AssistantApiErrorType.empty,
          'Empty reply',
        );
      }
      return reply;
    }

    developer.log(
      '[Assistant] Proxy HTTP ${response.statusCode}: ${response.body}',
      name: _feature,
    );
    throw AssistantApiException(
      _mapError(null, response.statusCode),
      '${response.statusCode}',
    );
  }

  AssistantApiErrorType _mapError(String? error, int status) {
    switch (error) {
      case 'config':
        return AssistantApiErrorType.config;
      case 'rate_limit':
        return AssistantApiErrorType.rateLimited;
      case 'network':
        return AssistantApiErrorType.network;
      case 'blocked':
        return AssistantApiErrorType.blocked;
      case 'server':
        return AssistantApiErrorType.server;
    }
    if (status == 429) return AssistantApiErrorType.rateLimited;
    if (status == 503) return AssistantApiErrorType.unavailable;
    return AssistantApiErrorType.server;
  }
}
