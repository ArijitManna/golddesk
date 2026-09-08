import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/services/fcm_service.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'core/services/version_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();

  // Initialize dependency injection
  await configureDependencies();
  await getIt<FcmService>().initialize();
  getIt<AuthBloc>().add(AuthCheckStatus());

  runApp(const GoldDeskApp());
}

class GoldDeskApp extends StatefulWidget {
  const GoldDeskApp({super.key});

  @override
  State<GoldDeskApp> createState() => _GoldDeskAppState();
}

class _GoldDeskAppState extends State<GoldDeskApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runVersionCheck());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runVersionCheck();
    }
  }

  void _runVersionCheck() {
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final retryCtx = AppRouter.rootNavigatorKey.currentContext;
        if (retryCtx != null) {
          VersionCheckService.checkForUpdate(retryCtx);
        }
      });
      return;
    }
    VersionCheckService.checkForUpdate(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>())],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
