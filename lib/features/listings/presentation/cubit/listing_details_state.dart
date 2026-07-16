part of 'listing_details_cubit.dart';

enum ListingDetailsStatus { initial, loading, success, failure }

class ListingDetailsState extends Equatable {
  const ListingDetailsState({
    this.status = ListingDetailsStatus.initial,
    this.property,
    this.errorMessage,
  });

  final ListingDetailsStatus status;
  final Property? property;
  final String? errorMessage;

  ListingDetailsState copyWith({
    ListingDetailsStatus? status,
    Property? property,
    String? errorMessage,
  }) {
    return ListingDetailsState(
      status: status ?? this.status,
      property: property ?? this.property,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, property, errorMessage];
}
