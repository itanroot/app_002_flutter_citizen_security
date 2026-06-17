import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/login_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/register_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/profile_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart";

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: "/login",
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == "/login";
      final isRegistering = state.matchedLocation == "/register";

      if (!isLoggedIn && !isLoggingIn && !isRegistering) return "/login";
      if (isLoggedIn && (isLoggingIn || isRegistering)) return "/profile";
      return null;
    },
    routes: [
      GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
      GoRoute(path: "/register", builder: (context, state) => const RegisterPage()),
      GoRoute(path: "/profile", builder: (context, state) => const ProfilePage()),
    ],
  );
});
