import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/property.dart';
import '../repositories/listing_repository.dart';

class GetListingById implements UseCase<Property, String> {
  const GetListingById(this._repository);

  final ListingRepository _repository;

  @override
  Future<Either<Failure, Property>> call(String id) {
    return _repository.getListingById(id);
  }
}
