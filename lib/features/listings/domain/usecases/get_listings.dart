import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/property.dart';
import '../repositories/listing_repository.dart';

class GetListings implements UseCase<List<Property>, GetListingsParams> {
  const GetListings(this._repository);

  final ListingRepository _repository;

  @override
  Future<Either<Failure, List<Property>>> call(GetListingsParams params) {
    return _repository.getListings(category: params.category);
  }
}

class GetListingsParams extends Equatable {
  const GetListingsParams({this.category});

  final String? category;

  @override
  List<Object?> get props => [category];
}
