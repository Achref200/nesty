import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';

class AssistantState extends Equatable {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String error; // '' = no error, else a user-facing message
  final String contextNote;

  const AssistantState({
    this.messages = const [],
    this.isTyping = false,
    this.error = '',
    this.contextNote = '',
  });

  bool get isEmpty => messages.isEmpty;
  bool get hasError => error.isNotEmpty;

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    String? contextNote,
  }) => AssistantState(
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    error: error ?? this.error,
    contextNote: contextNote ?? this.contextNote,
  );

  @override
  List<Object?> get props => [messages, isTyping, error, contextNote];
}
