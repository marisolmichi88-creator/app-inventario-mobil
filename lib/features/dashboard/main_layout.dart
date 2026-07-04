import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/scanner')) return 2;
    if (location.startsWith('/movements')) return 3;
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/scanner');
        break;
      case 3:
        context.go('/movements');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
              }
              return TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              );
            }),
          ),
          child: NavigationBar(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            height: 65,
            indicatorColor: actionColor.withValues(alpha: 0.12),
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                selectedIcon: Icon(Icons.home, color: actionColor),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                selectedIcon: Icon(Icons.inventory_2, color: actionColor),
                label: 'Productos',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                selectedIcon: Icon(Icons.qr_code_scanner, color: actionColor),
                label: 'Escáner',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                selectedIcon: Icon(Icons.swap_horiz, color: actionColor),
                label: 'Movimientos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
