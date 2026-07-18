import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/assistant_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../utils/assistant_brain.dart';
import 'assistant_state.dart';

/// Drives one contextual conversation. Created per surface (a modal sheet, a
/// listing helper, the filter helper…) with the [contextNote] describing what
/// the user is looking at, so the same assistant is specific everywhere.
class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(
    this._send, {
    this.userName,
    this.languageCode = 'en',
    String contextNote = '',
  }) : super(AssistantState(contextNote: contextNote));

  final SendMessageUseCase _send;
  final String? userName;
  final String languageCode;

  static const int _maxHistoryTurns = 20;
  int _seq = 0;

  void updateContext(String note) {
    if (note != state.contextNote) emit(state.copyWith(contextNote: note));
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isTyping) return;
    final userMsg = ChatMessage(
      id: _id(),
      role: ChatRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(messages: [...state.messages, userMsg], error: ''));
    await _generate();
  }

  Future<void> retry() async {
    if (state.isTyping || state.messages.isEmpty) return;
    await _generate();
  }

  Future<void> _generate() async {
    emit(state.copyWith(isTyping: true, error: ''));
    final result = await _send(
      systemPrompt: AssistantBrain.buildSystemPrompt(
        languageCode: languageCode,
        userName: userName,
        contextNote: state.contextNote,
      ),
      history: _historyForModel(),
    );
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isTyping: false, error: _messageFor(failure))),
      (reply) {
        final msg = ChatMessage(
          id: _id(),
          role: ChatRole.assistant,
          text: reply,
          createdAt: DateTime.now(),
        );
        emit(
          state.copyWith(
            messages: [...state.messages, msg],
            isTyping: false,
            error: '',
          ),
        );
      },
    );
  }

  /// Only the last [_maxHistoryTurns] non-empty messages are sent to the model.
  List<ChatMessage> _historyForModel() {
    final nonEmpty = state.messages
        .where((m) => m.text.trim().isNotEmpty)
        .toList();
    if (nonEmpty.length <= _maxHistoryTurns) return nonEmpty;
    return nonEmpty.sublist(nonEmpty.length - _maxHistoryTurns);
  }

  String _id() => 'm-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  String _messageFor(AssistantFailure failure) => switch (failure) {
    AssistantNetworkFailure() =>
      'You appear to be offline. Check your connection and try again.',
    AssistantConfigFailure() => 'The assistant isn\u2019t available right now.',
    AssistantBlockedFailure() =>
      'I can\u2019t help with that one \u2014 let\u2019s try something else.',
    AssistantRateLimitFailure() =>
      'The assistant is busy right now. Please try again in a moment.',
    AssistantServerFailure() => 'Something went wrong. Please try again.',
  };
}
