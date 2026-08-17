import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../services/fcm_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/connection_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/karigar_portal_repository.dart';
import '../../data/repositories/master_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/team_user_repository.dart';
import '../../data/repositories/tenant_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/dashboard/bloc/dashboard_cubit.dart';
import '../../features/orders/bloc/order_list_cubit.dart';
import '../../features/orders/bloc/create_order_cubit.dart';
import '../../features/orders/bloc/order_detail_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<FcmService>(() => FcmService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<KarigarPortalRepository>(
    () => KarigarPortalRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<MasterRepository>(
    () => MasterRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TeamUserRepository>(
    () => TeamUserRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TenantRepository>(
    () => TenantRepository(getIt<ApiClient>()),
  );

  // BLoCs / Cubits — AuthBloc must be a singleton so router redirect
  // and UI share the same auth session.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>(), getIt<FcmService>()),
  );
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(getIt<DashboardRepository>()),
  );
  getIt.registerFactory<OrderListCubit>(
    () => OrderListCubit(getIt<OrderRepository>()),
  );
  getIt.registerFactory<CreateOrderCubit>(
    () => CreateOrderCubit(getIt<OrderRepository>()),
  );
  getIt.registerFactory<OrderDetailCubit>(
    () => OrderDetailCubit(getIt<OrderRepository>()),
  );
}
