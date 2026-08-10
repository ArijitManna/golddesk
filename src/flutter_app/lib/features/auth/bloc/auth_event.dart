import 'package:equatable/equatable.dart';

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

  const AuthRegisterRequested({
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.password,
    this.address,
  });

  @override
  List<Object?> get props => [shopName, ownerName, mobile, email, password, address];
}

class AuthLogoutRequested extends AuthEvent {}
