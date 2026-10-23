import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/property_model.dart';
import 'listing_remote_data_source.dart';

/// Reads listings from the shared `listings` table in Supabase.
///
/// Expected columns match [PropertyModel.fromMap]. The traveller catalog only
/// receives published, bookable listings.
class SupabaseListingRemoteDataSource implements ListingRemoteDataSource {
  const SupabaseListingRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'listings';

  /// The home feed uses camelCase category ids ('entirePlace', 'sharedRoom',
  /// 'privateRoom') but the `listings.type` column stores snake_case. Map
  /// between them so filtering actually returns rows.
  static const _typeByCategory = <String, String>{
    'entirePlace': 'entire_place',
    'sharedRoom': 'shared_room',
    'privateRoom': 'private_room',
  };

  @override
  Future<List<PropertyModel>> getListings({String? category}) async {
    try {
      // Keep unpublished and synthetic rows out of the traveller catalog.
      final query = _client
          .from(_table)
          .select()
          .inFilter('status', ['published', 'active'])
          .eq('is_demo', false);
      final dbType = _typeByCategory[category];
      final rows = await (dbType == null ? query : query.eq('type', dbType));
      return (rows as List)
          .map((e) => PropertyModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PropertyModel> getListingById(String id) async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .inFilter('status', ['published', 'active'])
          .eq('is_demo', false)
          .single();
      return PropertyModel.fromMap(row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
