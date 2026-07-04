import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/models/project_model.dart';
import '../../data/models/movement_model.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/products_provider.dart';
import 'package:intl/intl.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementsProvider>().fetchMovements();
      context.read<ProductsProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, widget.project.name),
      body: Consumer2<MovementsProvider, ProductsProvider>(
        builder: (context, movementsProv, productsProv, child) {
          if (movementsProv.isLoading || productsProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar solo las salidas (OUT) asociadas a este proyecto
          final projectMovements = movementsProv.movements.where(
            (m) => m.projectId == widget.project.id && m.type == 'OUT'
          ).toList();

          double totalCost = 0.0;
          
          // Agrupar por producto para resumen (Opcional, pero aquí listamos todos los movimientos)
          List<Map<String, dynamic>> detailsList = [];

          for (var mov in projectMovements) {
            final product = productsProv.products.firstWhere(
              (p) => p.id == mov.productId, 
              orElse: () => productsProv.products.first // Fallback (should not happen if db intact)
            );
            
            double cost = product.price * mov.quantity;
            totalCost += cost;

            detailsList.add({
              'movement': mov,
              'product': product,
              'cost': cost,
            });
          }

          return Column(
            children: [
              // Header de Costos Totales
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E40AF), const Color(0xFF2563EB)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.tinted(const Color(0xFF3B82F6), alpha: 0.12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Presupuesto Consumido',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${projectMovements.length} retiros de materiales',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Lista de materiales usados
              Expanded(
                child: detailsList.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Sin materiales asignados',
                        subtitle: 'Aún no hay retiros de stock vinculados a este proyecto.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: detailsList.length,
                        itemBuilder: (context, index) {
                          final item = detailsList[index];
                          final MovementModel mov = item['movement'];
                          final product = item['product'];
                          final double cost = item['cost'];

                          DateTime parsedDate = DateTime.tryParse(mov.date) ?? DateTime.now();
                          String formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppShadows.card(isDark: isDark),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$formattedDate · ${mov.quantity} ${product.unit} (a \$${product.price})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${cost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
