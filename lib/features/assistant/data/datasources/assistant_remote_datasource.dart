import '../../domain/entities/chat_message.dart';

enum AssistantApiErrorType {
  config,
  network,
  blocked,
  server,
  empty,
  rateLimited,
  unavailable,
}

class AssistantApiException implements Exception {
  final AssistantApiErrorType type;
  final String message;
  AssistantApiException(this.type, this.message);
  @override
  String toString() => 'AssistantApiException($type): $message';
}

abstract class AssistantRemoteDataSource {
  Future<String> generateReply({
    required String systemPrompt,
    required List<ChatMessage> history,
    String? context,
    String? languageCode,
    String? userName,
  });
}

/// Try the primary model, then the fallback, retrying transient 503s. Shared by
/// every provider so reliability behaves identically.
mixin ModelFallbackMixin {
  Future<String> attemptModels(
    List<String> models,
    Future<String> Function(String model) call,
  ) async {
    final candidates = models.where((m) => m.trim().isNotEmpty).toList();
    if (candidates.isEmpty) {
      throw AssistantApiException(
        AssistantApiErrorType.config,
        'No model configured',
      );
    }

    AssistantApiException lastError = AssistantApiException(
      AssistantApiErrorType.server,
      'No model attempted',
    );

    for (final model in candidates) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          return await call(model);
        } on AssistantApiException catch (error) {
          lastError = error;
          // 503 = temporary spike: back off and retry the same model first.
          if (error.type == AssistantApiErrorType.unavailable && attempt < 2) {
            await Future.delayed(Duration(milliseconds: 700 * (attempt + 1)));
            continue;
          }
          switch (error.type) {
            case AssistantApiErrorType.config:
            case AssistantApiErrorType.network:
            case AssistantApiErrorType.blocked:
            case AssistantApiErrorType.empty:
              rethrow; // switching models can't help these
            case AssistantApiErrorType.server:
            case AssistantApiErrorType.rateLimited:
            case AssistantApiErrorType.unavailable:
              break; // give the next model a chance
          }
          break;
        }
      }
    }
    throw lastError;
  }
}
