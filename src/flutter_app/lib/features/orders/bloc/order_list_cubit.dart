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
  final String? activeDueFilter;
  final String? activeSource;
  final String? activeShopId;
  final String? activeShowroomId;
  final String? activeExternalCustomerId;
  final String? activeKarigarId;
  final String? activeDeliveryFrom;
  final String? activeDeliveryTo;

  const OrderListLoaded({
    required this.orders,
    required this.totalCount,
    required this.page,
    required this.hasMore,
    this.activeFilter,
    this.activeDueFilter,
    this.activeSource,
    this.activeShopId,
    this.activeShowroomId,
    this.activeExternalCustomerId,
    this.activeKarigarId,
    this.activeDeliveryFrom,
    this.activeDeliveryTo,
  });

  @override
  List<Object?> get props => [
    orders,
    totalCount,
    page,
    activeFilter,
    activeDueFilter,
    activeSource,
    activeShopId,
    activeShowroomId,
    activeExternalCustomerId,
    activeKarigarId,
    activeDeliveryFrom,
    activeDeliveryTo,
  ];
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

  /// [silent] keeps the current list on screen while refreshing.
  Future<void> loadOrders({
    String? status,
    String? due,
    String? search,
    String? source,
    String? shopId,
    String? showroomId,
    String? externalCustomerId,
    String? karigarId,
    String? deliveryFrom,
    String? deliveryTo,
    bool silent = false,
  }) async {
    if (!silent || state is! OrderListLoaded) emit(OrderListLoading());
    try {
      final response = await _repository.getOrders(
        status: status,
        due: due,
        search: search,
        source: source,
        shopId: shopId,
        showroomId: showroomId,
        externalCustomerId: externalCustomerId,
        karigarId: karigarId,
        deliveryFrom: deliveryFrom,
        deliveryTo: deliveryTo,
        page: 1,
        pageSize: 20,
      );
      emit(OrderListLoaded(
        orders: response.items,
        totalCount: response.totalCount,
        page: 1,
        hasMore: response.page < response.totalPages,
        activeFilter: status,
        activeDueFilter: due,
        activeSource: source,
        activeShopId: shopId,
        activeShowroomId: showroomId,
        activeExternalCustomerId: externalCustomerId,
        activeKarigarId: karigarId,
        activeDeliveryFrom: deliveryFrom,
        activeDeliveryTo: deliveryTo,
      ));
    } on ApiException catch (e) {
      if (!silent) emit(OrderListError(e.message));
    } catch (e) {
      if (!silent) emit(OrderListError('Failed to load orders'));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! OrderListLoaded || !currentState.hasMore) return;

    try {
      final response = await _repository.getOrders(
        status: currentState.activeFilter,
        due: currentState.activeDueFilter,
        source: currentState.activeSource,
        shopId: currentState.activeShopId,
        showroomId: currentState.activeShowroomId,
        externalCustomerId: currentState.activeExternalCustomerId,
        karigarId: currentState.activeKarigarId,
        deliveryFrom: currentState.activeDeliveryFrom,
        deliveryTo: currentState.activeDeliveryTo,
        page: currentState.page + 1,
        pageSize: 20,
      );
      emit(OrderListLoaded(
        orders: [...currentState.orders, ...response.items],
        totalCount: response.totalCount,
        page: response.page,
        hasMore: response.page < response.totalPages,
        activeFilter: currentState.activeFilter,
        activeDueFilter: currentState.activeDueFilter,
        activeSource: currentState.activeSource,
        activeShopId: currentState.activeShopId,
        activeShowroomId: currentState.activeShowroomId,
        activeExternalCustomerId: currentState.activeExternalCustomerId,
        activeKarigarId: currentState.activeKarigarId,
        activeDeliveryFrom: currentState.activeDeliveryFrom,
        activeDeliveryTo: currentState.activeDeliveryTo,
      ));
    } catch (_) {
      // Silently fail on load more
    }
  }
}
