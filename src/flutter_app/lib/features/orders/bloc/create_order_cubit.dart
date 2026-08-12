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
  final List<CustomerItem> customers;
  final List<Map<String, dynamic>> items;
  const CreateOrderDataLoaded(this.customers, this.items);
  @override
  List<Object?> get props => [customers.length, items.length];
}

// Cubit
class CreateOrderCubit extends Cubit<CreateOrderState> {
  final OrderRepository _repository;

  CreateOrderCubit(this._repository) : super(CreateOrderInitial());

  Future<void> loadFormData() async {
    try {
      final customers = await _repository.getCustomers();
      // Load items from API
      final itemsResponse = await _repository.getItems();
      emit(CreateOrderDataLoaded(customers, itemsResponse));
    } catch (_) {
      emit(CreateOrderDataLoaded(const [], const []));
    }
  }

  Future<void> createOrder(CreateOrderRequest request, {List<String?> itemImages = const []}) async {
    emit(CreateOrderLoading());
    try {
      final order = await _repository.createOrder(request);

      // Upload images for items that have them
      if (itemImages.isNotEmpty) {
        // Get full order detail to get item IDs
        final detail = await _repository.getOrderById(order.id);
        for (var i = 0; i < detail.items.length && i < itemImages.length; i++) {
          if (itemImages[i] != null) {
            try {
              await _repository.uploadOrderItemImage(detail.items[i].id, itemImages[i]!);
            } catch (_) {
              // Don't fail order creation if image upload fails
            }
          }
        }
      }

      emit(CreateOrderSuccess(order));
    } on ApiException catch (e) {
      emit(CreateOrderError(e.message));
    } catch (e) {
      emit(CreateOrderError('Failed to create order'));
    }
  }
}
