import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/models/product_model.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts();
      context.read<MovementsProvider>().fetchMovements();
      context.read<CategoriesProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final productsProvider = context.watch<ProductsProvider>();
    final movementsProvider = context.watch<MovementsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final categoriesProvider = context.watch<CategoriesProvider>();

    final products = productsProvider.products;
    final totalProducts = products.length;
    final lowStockProducts = products
        .where((p) => p.stock <= p.minStock)
        .length;
    final normalStockProducts = totalProducts - lowStockProducts;
    final totalValue = products.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.stock),
    );
    final totalCategories = categoriesProvider.categories.length;
    final recentMovements = movementsProvider.movements.take(2).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Hola, ${user?.name.split(' ').first ?? 'Admin'}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF60A5FA),
                          const Color(0xFF3B82F6),
                          const Color(0xFF2563EB),
                        ]
                      : [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF1E40AF),
                          const Color(0xFF1D4ED8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF1959AD),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user?.role == 'admin') ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Gestión de Usuarios',
                      onTap: () => context.push('/users'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.local_offer_outlined,
                      title: 'Gestión de Categorías',
                      onTap: () => context.push('/categories'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.warehouse_outlined,
                      title: 'Gestión de Almacenes',
                      onTap: () => context.push('/warehouses'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.business_center_outlined,
                      title: 'Gestión de Proyectos',
                      onTap: () => context.push('/projects'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'EXTRAS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.qr_code_2_outlined,
                      title: 'Generador de Etiquetas (QR)',
                      onTap: () => context.push('/qr-generator'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                  ],
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Catálogo de Productos',
                    onTap: () => context.push('/products'),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.compare_arrows_outlined,
                    title: 'Movimientos',
                    onTap: () => context.push('/movements'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.black12, height: 1),
                  ),
                  SwitchListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: isDark ? Colors.white : const Color(0xFF1959AD),
                      size: 22,
                    ),
                    title: Text(
                      themeProvider.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeTrackColor:
                        (isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF1959AD))
                            .withValues(alpha: 0.5),
                    activeThumbColor: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF1959AD),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.black12, height: 1),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout_outlined,
                    title: 'Cerrar Sesión',
                    iconColor: const Color(0xFFEF4444),
                    textColor: const Color(0xFFEF4444),
                    showTrailing: false,
                    onTap: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await productsProvider.fetchProducts();
          await movementsProvider.fetchMovements();
          await categoriesProvider.fetchCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 12),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumen general de inventario',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              if (user?.role == 'admin') ...[
                _buildMainValueCard(context, totalValue),
                const SizedBox(height: 24),
              ],

              // Cuadrícula de 4 tarjetas
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Productos Totales',
                        value: totalProducts.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF38BDF8),
                        underlineColor: const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Stock Crítico',
                        value: lowStockProducts.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                        underlineColor: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Stock Normal',
                        value: normalStockProducts.toString(),
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        underlineColor: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Categorías Registradas',
                        value: totalCategories.toString(),
                        icon: Icons.local_offer_outlined,
                        color: const Color(0xFF8B5CF6),
                        underlineColor: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),

              if (user?.role == 'admin') ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Distribución de Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/products'),
                      child: const Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDonutChartCard(
                  context,
                  totalProducts,
                  lowStockProducts,
                  normalStockProducts,
                ),
              ],

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Últimos movimientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/movements'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ver todos',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (movementsProvider.movements.length > 2) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF1959AD),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '+${movementsProvider.movements.length - 2}',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentMovements.isEmpty)
                _buildEmptyMovementsCard(context)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentMovements.length,
                  itemBuilder: (context, index) {
                    final mov = recentMovements[index];
                    final isEntry = mov.type == 'IN';
                    final product = productsProvider.products.firstWhere(
                      (p) => p.id == mov.productId,
                      orElse: () =>
                          ProductModel(code: 'N/A', name: 'Desconocido'),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isEntry
                                ? (isDark
                                      ? const Color(
                                          0xFF16A34A,
                                        ).withValues(alpha: 0.2)
                                      : const Color(0xFFDCFCE7))
                                : (isDark
                                      ? const Color(
                                          0xFFDC2626,
                                        ).withValues(alpha: 0.2)
                                      : const Color(0xFFFEE2E2)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEntry
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isEntry
                                ? (isDark
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF16A34A))
                                : (isDark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFDC2626)),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(mov.date.split('T').first),
                        trailing: Text(
                          '${isEntry ? '+' : '-'}${mov.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isEntry
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainValueCard(BuildContext context, double totalValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF60A5FA),
                  const Color(0xFF3B82F6),
                  const Color(0xFF2563EB),
                ]
              : [
                  const Color(0xFF1E3A8A),
                  const Color(0xFF1E40AF),
                  const Color(0xFF1D4ED8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '\$',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Valor total del inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF10B981),
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '+8.2% respecto al mes pasado',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color underlineColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 3,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: underlineColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard(
    BuildContext context,
    int total,
    int critical,
    int normal,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double criticalPct = total > 0 ? (critical / total) * 100 : 0;
    double normalPct = total > 0 ? (normal / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: critical.toDouble(),
                        color: const Color(0xFFEF4444), // Rojo
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: normal.toDouble(),
                        color: const Color(0xFF10B981), // Verde
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const Text('Productos\nTotales', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('Stock crítico', critical, criticalPct, const Color(0xFFEF4444), Theme.of(context).colorScheme.onSurface),
                const SizedBox(height: 16),
                _buildChartLegend('Stock normal', normal, normalPct, const Color(0xFF10B981), Theme.of(context).colorScheme.onSurface),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, int count, double pct, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500)),
              Text('$count productos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildEmptyMovementsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF), 
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFF3B82F6), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No hay movimientos recientes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                const Text('Cuando registres entradas o salidas, aparecerán aquí.', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/movements');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo\nMovimiento', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showTrailing = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = textColor ?? (isDark ? Colors.white70 : Colors.black87);
    final iColor = iconColor ?? (isDark ? Colors.white54 : Colors.black54);
    
    return ListTile(
      leading: Icon(icon, color: iColor),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: showTrailing ? Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26, size: 20) : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
