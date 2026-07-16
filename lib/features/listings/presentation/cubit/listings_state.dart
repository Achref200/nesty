part of 'listings_cubit.dart';

enum ListingsStatus { initial, loading, success, failure }

class ListingsState extends Equatable {
  const ListingsState({
    this.status = ListingsStatus.initial,
    this.properties = const [],
    this.category = 'all',
    this.filter = ListingFilter.empty,
    this.errorMessage,
  });

  final ListingsStatus status;
  final List<Property> properties;
  final String category;
  final ListingFilter filter;
  final String? errorMessage;

  ListingsState copyWith({
    ListingsStatus? status,
    List<Property>? properties,
    String? category,
    ListingFilter? filter,
    String? errorMessage,
  }) {
    return ListingsState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      category: category ?? this.category,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, properties, category, filter, errorMessage];
}
