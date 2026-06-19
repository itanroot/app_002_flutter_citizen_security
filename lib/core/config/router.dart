import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/login_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/register_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/pages/profile_page.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart";
import "package:seguridad_ciudadana_app/features/sos/presentation/pages/home_page.dart";
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/pages/incident_map_page.dart';
import 'package:seguridad_ciudadana_app/features/incident_map/presentation/pages/my_incidents_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: "/home",
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == "/login";
      final isRegistering = state.matchedLocation == "/register";
      final isHome = state.matchedLocation == "/home";
      final isMyIncidents = state.matchedLocation == '/my-incidents';

      if (!isLoggedIn && !isLoggingIn && !isRegistering && !isHome && !isMyIncidents) return "/home";
      if (isLoggedIn && (isLoggingIn || isRegistering)) return "/profile";
      return null;
    },
    routes: [
      GoRoute(path: '/incidents', builder: (context, state) => const IncidentMapPage()),
      GoRoute(path: '/my-incidents', builder: (context, state) => const MyIncidentsPage()),
      GoRoute(path: "/home", builder: (context, state) => const HomePage()),
      GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
      GoRoute(path: "/register", builder: (context, state) => const RegisterPage()),
      GoRoute(path: "/profile", builder: (context, state) => const ProfilePage()),
    ],
  );
});
