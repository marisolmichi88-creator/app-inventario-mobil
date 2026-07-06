import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/admin/users_screen.dart';
import '../../features/admin/categories_screen.dart';
import '../../features/admin/warehouses_screen.dart';
import '../../features/admin/projects_screen.dart';
import '../../features/admin/qr_generator_screen.dart';
import '../../features/admin/backup_screen.dart';
import '../../features/admin/reports_screen.dart';
import '../../features/inventory/products_screen.dart';
import '../../features/inventory/movements_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/main_layout.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isSplash = state.uri.toString() == '/splash';
        final isLoginRoute = state.uri.toString() == '/login';
        final isForgotPasswordRoute = state.uri.toString() == '/forgot-password';
        
        if (authProvider.isLoading) {
          return isSplash ? null : '/splash';
        }

        final isAuthenticated = authProvider.isAuthenticated;

        if (!isAuthenticated) {
          return (isLoginRoute || isForgotPasswordRoute) ? null : '/login';
        }

        if (isAuthenticated && (isLoginRoute || isSplash || isForgotPasswordRoute)) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/scanner',
              builder: (context, state) => const ScannerScreen(),
            ),
            GoRoute(
              path: '/movements',
              builder: (context, state) {
                final showForm = state.uri.queryParameters['showForm'] == 'true';
                return MovementsScreen(showForm: showForm);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/warehouses',
          builder: (context, state) => const WarehousesScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/qr-generator',
          builder: (context, state) => const QrGeneratorScreen(),
        ),
        GoRoute(
          path: '/backup',
          builder: (context, state) => const BackupScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    );
  }
}
