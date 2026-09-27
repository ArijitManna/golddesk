import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/order_repository.dart';

// State
abstract class CreateOrderState extends Equatable {
  const CreateOrderState();
  @override
  List<Object?> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class CreateOrderLoading extends CreateOrderState {}

class CreateOrderSuccess extends CreateOrderState {
  final OrderSummary order;
  const CreateOrderSuccess(this.order);
  @override
  List<Object?> get props => [order.id];
}

class CreateOrderError extends CreateOrderState {
  final String message;
  const CreateOrderError(this.message);
  @override
  List<Object?> get props => [message];
}

class CreateOrderDataLoaded extends CreateOrderState {
  final List<Map<String, dynamic>> items;
  final OrderDetail? existingOrder;
  const CreateOrderDataLoaded(this.items, {this.existingOrder});
  @override
  List<Object?> get props => [items.length, existingOrder?.id];
}

// Cubit
class CreateOrderCubit extends Cubit<CreateOrderState> {
  final OrderRepository _repository;

  CreateOrderCubit(this._repository) : super(CreateOrderInitial());

  Future<void> loadFormData({String? editOrderId}) async {
    try {
      final itemsResponse = await _repository.getItems();
      OrderDetail? existing;
      if (editOrderId != null) {
        existing = await _repository.getOrderById(editOrderId);
      }
      emit(CreateOrderDataLoaded(itemsResponse, existingOrder: existing));
    } catch (_) {
      emit(const CreateOrderDataLoaded([]));
    }
  }

  Future<void> createOrder(
    CreateOrderRequest request, {
    List<List<String>> itemImages = const [],
  }) async {
    emit(CreateOrderLoading());
    try {
      final order = await _repository.createOrder(request);
      await _uploadItemImages(
        order.id,
        itemImages,
        existingIds: request.items.map((e) => e.id).toList(),
      );
      emit(CreateOrderSuccess(order));
    } on ApiException catch (e) {
      emit(CreateOrderError(e.message));
    } catch (e) {
      emit(const CreateOrderError('Failed to create order'));
    }
  }

  Future<void> updateOrder(
    String orderId,
    CreateOrderRequest request, {
    List<List<String>> itemImages = const [],
    Map<String, List<String>> removedImages = const {},
  }) async {
    emit(CreateOrderLoading());
    try {
      final order = await _repository.updateOrder(orderId, request);
      for (final entry in removedImages.entries) {
        for (final path in entry.value) {
          try {
            await _repository.deleteOrderItemImage(entry.key, path);
          } catch (_) {}
        }
      }
      await _uploadItemImages(
        order.id,
        itemImages,
        existingIds: request.items.map((e) => e.id).toList(),
      );
      emit(CreateOrderSuccess(order));
    } on ApiException catch (e) {
      emit(CreateOrderError(e.message));
    } catch (e) {
      emit(const CreateOrderError('Failed to update order'));
    }
  }

  Future<void> _uploadItemImages(
    String orderId,
    List<List<String>> itemImages, {
    List<String?> existingIds = const [],
  }) async {
    if (itemImages.every((e) => e.isEmpty)) return;
    final detail = await _repository.getOrderById(orderId);
    final used = <String>{};
    for (var i = 0; i < itemImages.length; i++) {
      final paths = itemImages[i];
      if (paths.isEmpty) continue;

      String? targetId;
      final existingId = i < existingIds.length ? existingIds[i] : null;
      if (existingId != null && detail.items.any((it) => it.id == existingId)) {
        targetId = existingId;
      } else {
        final knownIds = existingIds.whereType<String>().toSet();
        for (final it in detail.items) {
          if (!used.contains(it.id) && !knownIds.contains(it.id)) {
            targetId = it.id;
            break;
          }
        }
        if (targetId == null) {
          for (final it in detail.items) {
            if (!used.contains(it.id)) {
              targetId = it.id;
              break;
            }
          }
        }
      }

      if (targetId == null) continue;
      used.add(targetId);
      for (final path in paths) {
        try {
          await _repository.addOrderItemImage(targetId, path);
        } catch (_) {}
      }
    }
  }
}
