import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/get_listing_by_id.dart';

part 'listing_details_state.dart';

/// Loads a single listing for the detail screen.
class ListingDetailsCubit extends Cubit<ListingDetailsState> {
  ListingDetailsCubit({required GetListingById getListingById})
    : _getListingById = getListingById,
      super(const ListingDetailsState());

  final GetListingById _getListingById;

  Future<void> load(String id) async {
    emit(state.copyWith(status: ListingDetailsStatus.loading));
    final result = await _getListingById(id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ListingDetailsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (property) {
        // Record the view for the agency's analytics.
        Analytics.view(property.id);
        emit(
          state.copyWith(
            status: ListingDetailsStatus.success,
            property: property,
          ),
        );
      },
    );
  }

  void toggleFavorite() {
    final current = state.property;
    if (current == null) return;
    emit(
      state.copyWith(
        property: current.copyWith(isFavorite: !current.isFavorite),
      ),
    );
  }
}
