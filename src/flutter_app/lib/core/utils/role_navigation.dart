import '../../data/models/auth_models.dart';
import '../../features/auth/bloc/auth_state.dart';

bool isKarigarUser(UserInfo? user) =>
    user?.role == 'Karigar' || user?.businessType == 'Karigar';

String homePathForUser(UserInfo? user) =>
    isKarigarUser(user) ? '/karigar/dashboard' : '/dashboard';

String homePathForAuthState(AuthState state) =>
    state is AuthAuthenticated ? homePathForUser(state.user) : '/login';

bool isKarigarAllowedPath(String location) {
  if (location.startsWith('/karigar')) return true;
  const allowed = {
    '/notifications',
    '/connections',
    '/reports',
    '/settings',
    '/settings/edit-profile',
    '/settings/notification-prefs',
  };
  return allowed.contains(location);
}
