import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../utils/role_navigation.dart';
import 'go_router_refresh_stream.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_approval_screen.dart';
import '../../features/admin/screens/platform_reports_screen.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/masters/screens/external_business_list_screen.dart';
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
import '../../features/orders/screens/order_comments_screen.dart';
import '../../features/orders/screens/order_timeline_screen.dart';
import '../../features/orders/screens/order_receipt_screen.dart';
import '../../features/orders/screens/assign_karigar_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/edit_profile_screen.dart';
import '../../features/settings/screens/notification_preferences_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/team_users_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
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
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (context, state) => const PlatformReportsScreen(),
      ),
      GoRoute(
        path: '/external-businesses',
        name: 'external-businesses',
        builder: (context, state) => const ExternalBusinessListScreen(),
      ),
      GoRoute(
        path: '/karigars',
        redirect: (context, state) => '/connections',
      ),
      GoRoute(
        path: '/items',
        name: 'items',
        builder: (context, state) => const ItemListScreen(),
      ),
      GoRoute(
        path: '/connections',
        name: 'connections',
        builder: (context, state) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          final due = state.uri.queryParameters['due'];
          final source = state.uri.queryParameters['source'];
          final shopId = state.uri.queryParameters['shopId'];
          final shopName = state.uri.queryParameters['shopName'];
          final showroomId = state.uri.queryParameters['showroomId'];
          final externalCustomerId =
              state.uri.queryParameters['externalCustomerId'];
          return BlocProvider(
            create: (_) => getIt<OrderListCubit>(),
            child: OrderListScreen(
              key: ValueKey(
                'orders_${status}_${due}_${source}_${shopId}_${showroomId}_$externalCustomerId',
              ),
              initialStatus: status,
              initialDue: due,
              initialSource: source,
              initialShopId: shopId,
              initialShopName: shopName,
              initialShowroomId: showroomId,
              initialExternalCustomerId: externalCustomerId,
            ),
          );
        },
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
        path: '/orders/:id/edit',
        name: 'edit-order',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CreateOrderCubit>(),
          child: CreateOrderScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id/receipt',
        name: 'order-receipt',
        builder: (context, state) =>
            OrderReceiptScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/comments/:channel',
        name: 'order-comments',
        builder: (context, state) => OrderCommentsScreen(
          orderId: state.pathParameters['id']!,
          channel: state.pathParameters['channel']!,
          conversationTitle: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: '/orders/:id/timeline',
        name: 'order-timeline',
        builder: (context, state) =>
            OrderTimelineScreen(orderId: state.pathParameters['id']!),
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
      GoRoute(
        path: '/settings/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/notification-prefs',
        name: 'notification-prefs',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/team-users',
        name: 'team-users',
        builder: (context, state) => const TeamUsersScreen(),
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
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          final assignmentStatus =
              state.uri.queryParameters['assignmentStatus'];
          final due = state.uri.queryParameters['due'];
          final shopId = state.uri.queryParameters['shopId'];
          final shopName = state.uri.queryParameters['shopName'];
          return KarigarOrdersScreen(
            key: ValueKey(
              'karigar_orders_${status}_${assignmentStatus}_${due}_$shopId',
            ),
            initialStatus: status,
            initialAssignmentStatus: assignmentStatus,
            initialDue: due,
            initialShopId: shopId,
            initialShopName: shopName,
          );
        },
      ),
      GoRoute(
        path: '/karigar/orders/:id/update',
        name: 'karigar-update-status',
        builder: (context, state) =>
            KarigarUpdateStatusScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/karigar/orders/:id/comments',
        name: 'karigar-order-comments',
        builder: (context, state) => OrderCommentsScreen(
          orderId: state.pathParameters['id']!,
          channel: 'ShopKarigar',
          conversationTitle: state.uri.queryParameters['title'],
        ),
      ),
    ],
    redirect: (context, state) {
      final authBloc = getIt<AuthBloc>();
      final authState = authBloc.state;
      final isOnAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/pending-approval' ||
          state.matchedLocation == '/';

      if (authState is AuthUnauthenticated && !isOnAuthPage) {
        return '/login';
      }

      if (authState is AuthAuthenticated && isOnAuthPage) {
        return homePathForUser(authState.user);
      }

      if (authState is AuthAuthenticated &&
          isKarigarUser(authState.user) &&
          !isKarigarAllowedPath(state.matchedLocation)) {
        return '/karigar/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
