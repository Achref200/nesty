import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<AppUser, SignUpParams> {
  const SignUp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      role: params.role,
    );
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
  });

  final String email;
  final String password;
  final String fullName;
  final UserRole role;

  @override
  List<Object?> get props => [email, password, fullName, role];
}
