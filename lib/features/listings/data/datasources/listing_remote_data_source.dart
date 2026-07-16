import '../models/property_model.dart';

/// Contract for the listings source. Implemented by Supabase and a local mock.
abstract interface class ListingRemoteDataSource {
  Future<List<PropertyModel>> getListings({String? category});

  Future<PropertyModel> getListingById(String id);
}
