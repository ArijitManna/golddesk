import 'package:equatable/equatable.dart';
import '../../../data/models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserInfo user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.userId];
}

class AuthUnauthenticated extends AuthState {}

class AuthPendingApproval extends AuthState {
  final String message;

  const AuthPendingApproval({this.message = 'Your account is pending approval.'});

  @override
  List<Object?> get props => [message];
}

class AuthRegistered extends AuthState {
  final String message;

  const AuthRegistered({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
