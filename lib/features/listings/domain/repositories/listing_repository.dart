import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/property.dart';

abstract interface class ListingRepository {
  Future<Either<Failure, List<Property>>> getListings({String? category});

  Future<Either<Failure, Property>> getListingById(String id);
}
