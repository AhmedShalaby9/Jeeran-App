import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthCompleteProfileEvent>(_onCompleteProfile);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthGetMeEvent>(_onGetMe);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.login(event.phone);
    result.fold((failure) => emit(AuthError(_mapFailure(failure))), (user) {
      emit(
        AuthPhoneChecked(
          user: user.isProfileComplete ? user : null,
          isProfileComplete: user.isProfileComplete,
        ),
      );
    });
  }

  Future<void> _onCompleteProfile(
    AuthCompleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.completeProfile(event.params);
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) {
        if (event.isStep1) {
          emit(AuthProfileStep1Completed(user));
        } else {
          emit(AuthProfileCompleted(user));
        }
      },
    );
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }

  Future<void> _onGetMe(AuthGetMeEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.getMe();
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) => emit(AuthMeLoaded(user)),
    );
  }

  Future<void> _onUpdateProfile(AuthUpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.completeProfile(event.params);
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) => emit(AuthProfileUpdated(user)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure _ => AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
