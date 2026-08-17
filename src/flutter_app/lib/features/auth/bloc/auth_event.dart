import 'package:equatable/equatable.dart';
import '../../../data/models/auth_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String shopName;
  final String ownerName;
  final String mobile;
  final String email;
  final String password;
  final String? address;
  final String businessType;

  const AuthRegisterRequested({
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.password,
    this.address,
    required this.businessType,
  });

  @override
  List<Object?> get props => [shopName, ownerName, mobile, email, password, address, businessType];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileSwitchRequested extends AuthEvent {
  final String tenantId;

  const AuthProfileSwitchRequested(this.tenantId);

  @override
  List<Object?> get props => [tenantId];
}

class AuthUserUpdated extends AuthEvent {
  final UserInfo user;
  const AuthUserUpdated(this.user);
  @override
  List<Object?> get props => [user.userId, user.shopName, user.fullName];
}
