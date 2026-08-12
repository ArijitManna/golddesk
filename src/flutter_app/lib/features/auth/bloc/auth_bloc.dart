import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final isLoggedIn = await _authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(AuthUnauthenticated());
      return;
    }

    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.login(
        LoginRequest(email: event.email, password: event.password),
      );
      emit(AuthAuthenticated(response.user));
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        // Could be pending approval or rejected
        emit(AuthPendingApproval(message: e.message));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError('Login failed. Please try again.'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.register(
        RegisterRequest(
          shopName: event.shopName,
          ownerName: event.ownerName,
          mobile: event.mobile,
          email: event.email,
          password: event.password,
          address: event.address,
        ),
      );
      emit(AuthRegistered(message: response.message));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticated(event.user));
  }
}
