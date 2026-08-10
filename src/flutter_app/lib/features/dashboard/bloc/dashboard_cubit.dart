import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/dashboard_repository.dart';

// State
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final ShopDashboardData data;
  const DashboardLoaded(this.data);
  @override
  List<Object?> get props => [data.totalOrders];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final data = await _repository.getShopDashboard();
      emit(DashboardLoaded(data));
    } on ApiException catch (e) {
      emit(DashboardError(e.message));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard'));
    }
  }
}
