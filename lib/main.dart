import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'features/auth/auth_provider.dart';
import 'core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'data/providers/users_provider.dart';
import 'data/providers/categories_provider.dart';
import 'data/providers/warehouses_provider.dart';
import 'data/providers/projects_provider.dart';
import 'data/providers/products_provider.dart';
import 'data/providers/movements_provider.dart';
import 'data/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  await DatabaseHelper().database;

  runApp(const ProenergimApp());
}

class ProenergimApp extends StatelessWidget {
  const ProenergimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => WarehousesProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProxyProvider<ProductsProvider, MovementsProvider>(
          create: (context) =>
              MovementsProvider(context.read<ProductsProvider>()),
          update: (context, productsProvider, previousMovementsProvider) =>
              previousMovementsProvider ?? MovementsProvider(productsProvider),
        ),
      ],
      child: const _AppWithTheme(),
    );
  }
}

class _AppWithTheme extends StatefulWidget {
  const _AppWithTheme();

  @override
  State<_AppWithTheme> createState() => _AppWithThemeState();
}

class _AppWithThemeState extends State<_AppWithTheme> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Proenergim stock',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1959AD),
        scaffoldBackgroundColor: const Color(0xFFF0F9FF), // color-bg-soft
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1959AD),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1959AD),
          secondary: Color(0xFF0EA5E9), // color-primary
          surface: Colors.white,
          onSurface: Color(0xFF0F172A), // color-text
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1959AD),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1959AD), width: 2),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF1959AD),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1959AD),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1959AD),
          secondary: Color(0xFF38BDF8), // color-primary-light
          surface: Color(0xFF1E293B),
          onSurface: Color(0xFFF1F5F9),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 1,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1959AD),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
