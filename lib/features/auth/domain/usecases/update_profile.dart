import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

/// Updates the signed-in user's editable profile fields (name, role).
class UpdateProfile implements UseCase<AppUser, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      fullName: params.fullName,
      role: params.role,
      avatarUrl: params.avatarUrl,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({this.fullName, this.role, this.avatarUrl});

  final String? fullName;
  final UserRole? role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [fullName, role, avatarUrl];
}
