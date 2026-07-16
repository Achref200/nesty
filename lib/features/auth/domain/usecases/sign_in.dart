import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignIn implements UseCase<AppUser, SignInParams> {
  const SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignInParams params) {
    return _repository.signIn(email: params.email, password: params.password);
  }
}

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
