import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/fcm_service.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final FcmService _fcmService;

  AuthBloc(this._authRepository, this._fcmService) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileSwitchRequested>(_onProfileSwitch);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final isLoggedIn = await _authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(AuthUnauthenticated());
      return;
    }

    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
      _registerCurrentDeviceToken();
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.login(
        LoginRequest(
          email: event.email,
          password: event.password,
          fcmToken: await _currentFcmToken(),
        ),
      );
      emit(AuthAuthenticated(response.user));
      _listenForTokenRefresh();
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

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
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
          businessType: event.businessType,
        ),
      );
      emit(AuthRegistered(message: response.message));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _registerCurrentDeviceToken() async {
    try {
      final token = await _fcmService.getToken();
      if (token != null) {
        await _authRepository.updateFcmToken(token);
        _listenForTokenRefresh();
      }
    } catch (_) {
      // Token registration must not prevent an existing session from loading.
    }
  }

  Future<String?> _currentFcmToken() async {
    try {
      return await _fcmService.getToken();
    } catch (_) {
      return null;
    }
  }

  void _listenForTokenRefresh() {
    _fcmService.listenForTokenRefresh((token) async {
      try {
        await _authRepository.updateFcmToken(token);
      } catch (_) {
        // A later refresh or login will retry token registration.
      }
    });
  }

  Future<void> _onProfileSwitch(
    AuthProfileSwitchRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _authRepository.switchProfile(
        event.tenantId,
        fcmToken: await _currentFcmToken(),
      );
      emit(AuthAuthenticated(response.user));
      _listenForTokenRefresh();
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Could not switch business profile. Please try again.'));
    }
  }

  Future<void> _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.user));
  }
}
