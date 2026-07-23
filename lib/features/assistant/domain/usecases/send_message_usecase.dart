import 'package:dartz/dartz.dart';

import '../entities/assistant_failure.dart';
import '../entities/chat_message.dart';
import '../repositories/assistant_repository.dart';

class SendMessageUseCase {
  final AssistantRepository repository;
  const SendMessageUseCase(this.repository);

  Future<Either<AssistantFailure, String>> call({
    required String systemPrompt,
    required List<ChatMessage> history,
    String? context,
    String? languageCode,
    String? userName,
  }) => repository.generateReply(
        systemPrompt: systemPrompt,
        history: history,
        context: context,
        languageCode: languageCode,
        userName: userName,
      );
}
