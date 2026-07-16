import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/listing_remote_data_source.dart';

class ListingRepositoryImpl implements ListingRepository {
  const ListingRepositoryImpl(this._remote);

  final ListingRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Property>>> getListings({
    String? category,
  }) async {
    try {
      final listings = await _remote.getListings(category: category);
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Property>> getListingById(String id) async {
    try {
      final listing = await _remote.getListingById(id);
      return Right(listing);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
