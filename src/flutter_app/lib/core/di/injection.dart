import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/karigar_portal_repository.dart';
import '../../data/repositories/master_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/dashboard/bloc/dashboard_cubit.dart';
import '../../features/orders/bloc/order_list_cubit.dart';
import '../../features/orders/bloc/create_order_cubit.dart';
import '../../features/orders/bloc/order_detail_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<AdminRepository>(
      () => AdminRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<DashboardRepository>(
      () => DashboardRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<KarigarPortalRepository>(
      () => KarigarPortalRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<MasterRepository>(
      () => MasterRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepository(getIt<ApiClient>()));

  // BLoCs / Cubits
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<DashboardCubit>(
      () => DashboardCubit(getIt<DashboardRepository>()));
  getIt.registerFactory<OrderListCubit>(
      () => OrderListCubit(getIt<OrderRepository>()));
  getIt.registerFactory<CreateOrderCubit>(
      () => CreateOrderCubit(getIt<OrderRepository>()));
  getIt.registerFactory<OrderDetailCubit>(
      () => OrderDetailCubit(getIt<OrderRepository>()));
}
