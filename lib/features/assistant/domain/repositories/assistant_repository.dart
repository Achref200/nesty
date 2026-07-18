import 'package:dartz/dartz.dart';

import '../entities/assistant_failure.dart';
import '../entities/chat_message.dart';

abstract class AssistantRepository {
  Future<Either<AssistantFailure, String>> generateReply({
    required String systemPrompt,
    required List<ChatMessage> history,
  });
}
