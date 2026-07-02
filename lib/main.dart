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
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => WarehousesProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProxyProvider<ProductsProvider, MovementsProvider>(
          create: (context) => MovementsProvider(context.read<ProductsProvider>()),
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
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF059669),
          surface: Colors.white,
          background: Color(0xFFF8FAFC),
          onBackground: Color(0xFF1E293B),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
          onBackground: Color(0xFFF1F5F9),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E293B),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
