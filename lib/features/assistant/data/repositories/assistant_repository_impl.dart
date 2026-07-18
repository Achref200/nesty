import 'package:dartz/dartz.dart';

import '../../domain/entities/assistant_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_remote_datasource.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final AssistantRemoteDataSource remoteDataSource;
  AssistantRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<AssistantFailure, String>> generateReply({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async {
    try {
      final reply = await remoteDataSource.generateReply(
        systemPrompt: systemPrompt,
        history: history,
      );
      return Right(reply);
    } on AssistantApiException catch (e) {
      return Left(_mapException(e));
    } catch (_) {
      return const Left(AssistantServerFailure());
    }
  }

  AssistantFailure _mapException(AssistantApiException e) {
    switch (e.type) {
      case AssistantApiErrorType.config:
        return const AssistantConfigFailure();
      case AssistantApiErrorType.network:
        return const AssistantNetworkFailure();
      case AssistantApiErrorType.blocked:
        return const AssistantBlockedFailure();
      case AssistantApiErrorType.rateLimited:
      case AssistantApiErrorType.unavailable:
        return const AssistantRateLimitFailure();
      case AssistantApiErrorType.server:
      case AssistantApiErrorType.empty:
        return const AssistantServerFailure();
    }
  }
}
