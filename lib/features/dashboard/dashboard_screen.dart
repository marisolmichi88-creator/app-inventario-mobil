import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/global_search_delegate.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';
import '../../core/services/pdf_service.dart';
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
    });
  }

  Future<void> _exportToCSV(BuildContext context, List<MovementModel> movements, List<ProductModel> products) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["ID", "Fecha", "Tipo", "Producto SKU", "Producto Nombre", "Cantidad", "Almacen ID", "Proyecto ID", "Notas"]);

      for (var mov in movements) {
        final product = products.firstWhere((p) => p.id == mov.productId, orElse: () => ProductModel(code: 'N/A', name: 'Desconocido'));
        rows.add([
          mov.id,
          mov.date,
          mov.type,
          product.code,
          product.name,
          mov.quantity,
          mov.warehouseId,
          mov.projectId ?? '',
          mov.notes ?? ''
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getExternalStorageDirectory(); // Android
      // Si es otro SO u otra config, path_provider maneja el path
      final path = "${directory?.path ?? '/storage/emulated/0/Download'}/movimientos_proenergim_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado a: $path'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final productsProvider = context.watch<ProductsProvider>();
    final movementsProvider = context.watch<MovementsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final products = productsProvider.products;
    final totalProducts = products.length;
    final lowStockProducts = products.where((p) => p.stock <= p.minStock).length;
    final totalValue = products.fold<double>(0, (sum, item) => sum + (item.price * item.stock));
    final recentMovements = movementsProvider.movements.take(5).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1959AD)),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1959AD), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
            if (user?.role == 'admin') ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Gestión de Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/users');
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Gestión de Categorías'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/categories');
                },
              ),
              ListTile(
                leading: const Icon(Icons.warehouse),
                title: const Text('Gestión de Almacenes'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/warehouses');
                },
              ),
              ListTile(
                leading: const Icon(Icons.business_center),
                title: const Text('Gestión de Proyectos'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/projects');
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Extras', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Generador de Etiquetas (QR)'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/qr-generator');
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Catálogo de Productos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Movimientos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/movements');
              },
            ),
            const Divider(),
            SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: themeProvider.isDarkMode ? Colors.amber : Colors.blueGrey,
              ),
              title: const Text('Modo Oscuro'),
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
              },
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
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenido, ${user?.name.split(' ').first ?? 'Usuario'}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              const Text('Resumen general de inventario', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),
              
              if (user?.role == 'admin')
                _buildMainValueCard(totalValue),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      title: 'Productos Totales',
                      value: totalProducts.toString(),
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF1959AD),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      title: 'Stock Crítico',
                      value: lowStockProducts.toString(),
                      icon: Icons.warning_rounded,
                      color: lowStockProducts > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                     child: Text(
                       'Últimos Movimientos',
                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                  if (user?.role == 'admin')
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1959AD).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.download_rounded, color: Color(0xFF1959AD), size: 20),
                            SizedBox(width: 4),
                            Text('Exportar', style: TextStyle(color: Color(0xFF1959AD), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    onSelected: (value) async {
                      if (value == 'CSV') {
                        _exportToCSV(context, movementsProvider.movements, productsProvider.products);
                      } else if (value == 'PDF') {
                        await PdfService.generateAndPrintMovementsReport(
                          movementsProvider.movements, 
                          productsProvider.products
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'PDF',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text('Exportar a PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'CSV',
                        child: ListTile(
                          leading: Icon(Icons.table_chart, color: Colors.green),
                          title: Text('Exportar a Excel (CSV)'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (recentMovements.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No hay movimientos recientes', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
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
                      orElse: () => ProductModel(code: 'N/A', name: 'Desconocido')
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isEntry ? Colors.green.shade50 : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEntry ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isEntry ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(mov.date.split('T').first),
                        trailing: Text(
                          '${isEntry ? '+' : '-'}${mov.quantity}', 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 18,
                            color: isEntry ? Colors.green.shade700 : Colors.red.shade700
                          )
                        ),
                      ),
                    );
                  },
                ),

              if (user?.role == 'admin') ...[
                const SizedBox(height: 32),
                 Text('Distribución de Productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                 const SizedBox(height: 16),
                 Container(
                   height: 200,
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Theme.of(context).cardTheme.color ?? Colors.white,
                     borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ]
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: (totalProducts - lowStockProducts).toDouble(),
                          color: const Color(0xFF059669),
                          title: '${totalProducts - lowStockProducts}',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (lowStockProducts > 0)
                          PieChartSectionData(
                            value: lowStockProducts.toDouble(),
                            color: const Color(0xFFDC2626),
                            title: '$lowStockProducts',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required BuildContext context, required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.1 : 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMainValueCard(double totalValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)], // Verde vibrante
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valor Total del Inventario', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text('\$${totalValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ],
      ),
    );
  }
}
