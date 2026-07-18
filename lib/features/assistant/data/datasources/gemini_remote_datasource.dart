import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../../core/config/ai_config.dart';
import '../../domain/entities/chat_message.dart';
import 'assistant_remote_datasource.dart';

class GeminiRemoteDataSourceImpl
    with ModelFallbackMixin
    implements AssistantRemoteDataSource {
  final http.Client client;
  GeminiRemoteDataSourceImpl({required this.client});
  static const String _feature = 'Assistant';

  @override
  Future<String> generateReply({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey.isEmpty) {
      throw AssistantApiException(
        AssistantApiErrorType.config,
        'Missing assistant API key',
      );
    }

    final contents = history
        .where((m) => m.text.trim().isNotEmpty)
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
        )
        .toList();

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    };

    return attemptModels([
      AiConfig.model,
      AiConfig.fallbackModel,
    ], (model) => _requestModel(model, apiKey, requestBody));
  }

  Future<String> _requestModel(
    String model,
    String apiKey,
    Map<String, dynamic> requestBody,
  ) async {
    final url = '${AiConfig.baseUrl}/models/$model:generateContent';

    late final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      developer.log('[Assistant] Network error: $error', name: _feature);
      throw AssistantApiException(
        AssistantApiErrorType.network,
        error.toString(),
      );
    }

    if (response.statusCode == 429) {
      throw AssistantApiException(
        AssistantApiErrorType.rateLimited,
        response.body,
      );
    }
    if (response.statusCode == 503) {
      throw AssistantApiException(
        AssistantApiErrorType.unavailable,
        response.body,
      );
    }
    if (response.statusCode != 200) {
      developer.log(
        '[Assistant] HTTP ${response.statusCode} on $model: ${response.body}',
        name: _feature,
      );
      throw AssistantApiException(
        AssistantApiErrorType.server,
        '${response.statusCode}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
    if (promptFeedback != null && promptFeedback['blockReason'] != null) {
      throw AssistantApiException(
        AssistantApiErrorType.blocked,
        'Prompt blocked',
      );
    }

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw AssistantApiException(AssistantApiErrorType.empty, 'No candidates');
    }

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final finishReason = firstCandidate['finishReason'];
    final content = firstCandidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;

    final text = (parts ?? const [])
        .map((p) => (p as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join()
        .trim();

    if (text.isEmpty) {
      if (finishReason == 'SAFETY' || finishReason == 'PROHIBITED_CONTENT') {
        throw AssistantApiException(
          AssistantApiErrorType.blocked,
          'Response blocked',
        );
      }
      throw AssistantApiException(
        AssistantApiErrorType.empty,
        'Empty response',
      );
    }
    return text;
  }
}
