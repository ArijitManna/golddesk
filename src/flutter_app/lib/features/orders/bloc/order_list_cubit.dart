import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/order_repository.dart';

// State
abstract class OrderListState extends Equatable {
  const OrderListState();
  @override
  List<Object?> get props => [];
}

class OrderListInitial extends OrderListState {}

class OrderListLoading extends OrderListState {}

class OrderListLoaded extends OrderListState {
  final List<OrderSummary> orders;
  final int totalCount;
  final int page;
  final bool hasMore;
  final String? activeFilter;

  const OrderListLoaded({
    required this.orders,
    required this.totalCount,
    required this.page,
    required this.hasMore,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [orders.length, totalCount, page, activeFilter];
}

class OrderListError extends OrderListState {
  final String message;
  const OrderListError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class OrderListCubit extends Cubit<OrderListState> {
  final OrderRepository _repository;

  OrderListCubit(this._repository) : super(OrderListInitial());

  Future<void> loadOrders({String? status, String? search}) async {
    emit(OrderListLoading());
    try {
      final response = await _repository.getOrders(
        status: status,
        search: search,
        page: 1,
        pageSize: 20,
      );
      emit(OrderListLoaded(
        orders: response.items,
        totalCount: response.totalCount,
        page: 1,
        hasMore: response.page < response.totalPages,
        activeFilter: status,
      ));
    } on ApiException catch (e) {
      emit(OrderListError(e.message));
    } catch (e) {
      emit(OrderListError('Failed to load orders'));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! OrderListLoaded || !currentState.hasMore) return;

    try {
      final response = await _repository.getOrders(
        status: currentState.activeFilter,
        page: currentState.page + 1,
        pageSize: 20,
      );
      emit(OrderListLoaded(
        orders: [...currentState.orders, ...response.items],
        totalCount: response.totalCount,
        page: response.page,
        hasMore: response.page < response.totalPages,
        activeFilter: currentState.activeFilter,
      ));
    } catch (_) {
      // Silently fail on load more
    }
  }
}
