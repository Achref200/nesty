import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/local_store.dart';

/// Holds the set of listing ids the user has saved. Backed by [LocalStore] so
/// favourites persist across launches — no backend required.
class SavedCubit extends Cubit<SavedState> {
  SavedCubit() : super(const SavedState()) {
    _restore();
  }

  static const _key = 'saved.ids';

  void _restore() {
    final ids = LocalStore.instance.getStringList(_key).toSet();
    emit(SavedState(ids: ids));
  }

  bool isSaved(String id) => state.ids.contains(id);

  Future<void> toggle(String id) async {
    final next = Set<String>.from(state.ids);
    if (!next.add(id)) next.remove(id);
    emit(SavedState(ids: next));
    await LocalStore.instance.setStringList(_key, next.toList());
  }
}

class SavedState extends Equatable {
  const SavedState({this.ids = const {}});

  final Set<String> ids;

  int get count => ids.length;

  @override
  List<Object?> get props => [ids];
}
