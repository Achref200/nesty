import 'package:flutter/foundation.dart';

import '../../../../core/services/local_store.dart';
import '../../domain/entities/property.dart';
import '../models/property_model.dart';

/// On-device store for listings the host publishes from inside the app. It
/// keeps an in-memory, reactive list (so screens rebuild instantly) and mirrors
/// every change into [LocalStore] so published places survive a restart.
class LocalListingsStore extends ChangeNotifier {
  LocalListingsStore() {
    _load();
  }

  static const _key = 'listings.user';

  final List<PropertyModel> _items = [];

  /// Published listings, newest first.
  List<Property> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  void _load() {
    _items
      ..clear()
      ..addAll(
        LocalStore.instance.getJsonList(_key).map(PropertyModel.fromMap),
      );
  }

  Future<void> add(PropertyModel property) async {
    _items.insert(0, property);
    await _persist();
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      LocalStore.instance.setJsonList(_key, _items.map((p) => p.toMap()).toList());
}
