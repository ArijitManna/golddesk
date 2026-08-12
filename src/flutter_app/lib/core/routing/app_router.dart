import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_approval_screen.dart';
import '../../features/masters/screens/customer_list_screen.dart';
import '../../features/masters/screens/karigar_list_screen.dart';
import '../../features/masters/screens/item_list_screen.dart';
import '../../features/dashboard/bloc/dashboard_cubit.dart';
import '../../features/dashboard/screens/shop_dashboard_screen.dart';
import '../../features/karigar_portal/screens/karigar_dashboard_screen.dart';
import '../../features/karigar_portal/screens/karigar_orders_screen.dart';
import '../../features/karigar_portal/screens/karigar_update_status_screen.dart';
import '../../features/orders/bloc/order_list_cubit.dart';
import '../../features/orders/bloc/create_order_cubit.dart';
import '../../features/orders/bloc/order_detail_cubit.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/orders/screens/create_order_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_receipt_screen.dart';
import '../../features/orders/screens/assign_karigar_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      // Shop Owner routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DashboardCubit>(),
          child: const ShopDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/approvals',
        name: 'admin-approvals',
        builder: (context, state) => const AdminApprovalScreen(),
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/karigars',
        name: 'karigars',
        builder: (context, state) => const KarigarListScreen(),
      ),
      GoRoute(
        path: '/items',
        name: 'items',
        builder: (context, state) => const ItemListScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OrderListCubit>(),
          child: const OrderListScreen(),
        ),
      ),
      GoRoute(
        path: '/orders/new',
        name: 'create-order',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CreateOrderCubit>(),
          child: const CreateOrderScreen(),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order-detail',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OrderDetailCubit>(),
          child: OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/assign',
        name: 'assign-karigar',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OrderDetailCubit>(),
          child: AssignKarigarScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/receipt',
        name: 'order-receipt',
        builder: (context, state) => OrderReceiptScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Karigar Portal routes
      GoRoute(
        path: '/karigar/dashboard',
        name: 'karigar-dashboard',
        builder: (context, state) => const KarigarDashboardScreen(),
      ),
      GoRoute(
        path: '/karigar/orders',
        name: 'karigar-orders',
        builder: (context, state) => const KarigarOrdersScreen(),
      ),
      GoRoute(
        path: '/karigar/orders/:id/update',
        name: 'karigar-update-status',
        builder: (context, state) => KarigarUpdateStatusScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
    ],
    redirect: (context, state) {
      final authBloc = getIt<AuthBloc>();
      final authState = authBloc.state;
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/pending-approval' ||
          state.matchedLocation == '/';

      if (authState is AuthAuthenticated && isOnAuthPage) {
        // Role-based redirect
        if (authState.user.role == 'Karigar') {
          return '/karigar/dashboard';
        }
        return '/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
