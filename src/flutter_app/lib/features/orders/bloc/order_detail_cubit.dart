import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/order_repository.dart';

// State
abstract class OrderDetailState extends Equatable {
  const OrderDetailState();
  @override
  List<Object?> get props => [];
}

class OrderDetailInitial extends OrderDetailState {}

class OrderDetailLoading extends OrderDetailState {}

class OrderDetailLoaded extends OrderDetailState {
  final OrderDetail order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order.id, order.status];
}

class OrderDetailError extends OrderDetailState {
  final String message;
  const OrderDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class AssignKarigarLoading extends OrderDetailState {}

class AssignKarigarSuccess extends OrderDetailState {}

// Cubit
class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _repository;

  OrderDetailCubit(this._repository) : super(OrderDetailInitial());

  Future<void> loadOrder(String orderId) async {
    emit(OrderDetailLoading());
    try {
      final order = await _repository.getOrderById(orderId);
      emit(OrderDetailLoaded(order));
    } on ApiException catch (e) {
      emit(OrderDetailError(e.message));
    } catch (e) {
      emit(OrderDetailError('Failed to load order details'));
    }
  }

  Future<void> assignKarigar(
    String orderId,
    AssignKarigarRequest request,
  ) async {
    emit(AssignKarigarLoading());
    try {
      await _repository.assignKarigar(orderId, request);
      emit(AssignKarigarSuccess());
      // Reload order to reflect changes
      await loadOrder(orderId);
    } on ApiException catch (e) {
      emit(OrderDetailError(e.message));
    } catch (e) {
      emit(OrderDetailError('Failed to assign Karigar'));
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _repository.cancelOrder(orderId, reason: reason);
      await loadOrder(orderId);
      return true;
    } on ApiException catch (e) {
      emit(OrderDetailError(e.message));
      return false;
    } catch (_) {
      emit(const OrderDetailError('Failed to cancel order'));
      return false;
    }
  }

  Future<bool> respondToOrder(
    String orderId, {
    required bool accept,
    String? note,
  }) async {
    try {
      await _repository.respondToOrder(orderId, accept: accept, note: note);
      await loadOrder(orderId);
      return true;
    } on ApiException catch (e) {
      emit(OrderDetailError(e.message));
      return false;
    } catch (_) {
      emit(const OrderDetailError('Failed to respond to order'));
      return false;
    }
  }

  Future<bool> updateOrderStatus(
    String orderId, {
    required String status,
    String? remarks,
  }) async {
    try {
      await _repository.updateOrderStatus(
        orderId,
        status: status,
        remarks: remarks,
      );
      await loadOrder(orderId);
      return true;
    } on ApiException catch (e) {
      emit(OrderDetailError(e.message));
      return false;
    } catch (_) {
      emit(const OrderDetailError('Failed to update order status'));
      return false;
    }
  }
}
