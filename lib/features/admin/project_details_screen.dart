import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/models/project_model.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/users_provider.dart';
import '../inventory/widgets/movement_form_dialog.dart';
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
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, widget.project.name),
      body: Consumer3<MovementsProvider, ProductsProvider, UsersProvider>(
        builder: (context, movementsProv, productsProv, usersProv, child) {
          if (movementsProv.isLoading || productsProv.isLoading || usersProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar solo las salidas (OUT) asociadas a este proyecto
          final projectMovements = movementsProv.movements
              .where((m) => m.projectId == widget.project.id && m.type == 'OUT')
              .toList();

          double totalCost = 0.0;

          // Agrupar por producto para resumen (Opcional, pero aquí listamos todos los movimientos)
          List<Map<String, dynamic>> detailsList = [];

          for (var mov in projectMovements) {
            final matchProds = productsProv.products.where((p) => p.id == mov.productId).toList();
            if (matchProds.isEmpty) continue;
            final product = matchProds.first;

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
                  boxShadow: AppShadows.tinted(
                    const Color(0xFF3B82F6),
                    alpha: 0.12,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.project.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Presupuesto', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('\$${widget.project.budget.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white30),
                        Column(
                          children: [
                            const Text('Costo Material', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('\$${totalCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white30),
                        Column(
                          children: [
                            const Text('Utilidad', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '\$${(widget.project.budget - totalCost).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: (widget.project.budget - totalCost) >= 0 ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${projectMovements.length} insumos asociados',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
                        subtitle:
                            'Aún no hay retiros de stock vinculados a este proyecto.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: detailsList.length,
                        itemBuilder: (context, index) {
                          final item = detailsList[index];
                          final MovementModel mov = item['movement'];
                          final product = item['product'];
                          final double cost = item['cost'];

                          DateTime parsedDate =
                              DateTime.tryParse(mov.date) ?? DateTime.now();
                          String formattedDate = DateFormat(
                            'dd/MM/yyyy',
                          ).format(parsedDate);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
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
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$formattedDate · ${mov.quantity} ${product.unit} (a \$${product.price})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Builder(
                                          builder: (context) {
                                            final worker = usersProv.users.firstWhere(
                                              (u) => u.authUserId == mov.userId || u.id == mov.userId,
                                              orElse: () => UserModel(name: 'No asignado', email: '', password: '', role: ''),
                                            );
                                            return Row(
                                              children: [
                                                Icon(Icons.person_outline, size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Asignado a: ${worker.name}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        if (mov.notes != null && mov.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            mov.notes!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: mov.notes!.contains('PENDIENTE')
                                                  ? Colors.orange.shade700
                                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${cost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
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
      floatingActionButton: adminFab(
        context: context,
        label: 'Asociar Material',
        onPressed: () async {
          final movementsProvider = context.read<MovementsProvider>();
          final productsProvider = context.read<ProductsProvider>();

          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: MovementFormDialog(
                prefilledProjectId: widget.project.id,
                prefilledType: 'OUT',
              ),
            ),
          );

          if (result == true) {
            movementsProvider.fetchMovements();
            productsProvider.fetchProducts();
          }
        },
      ),
    );
  }
}
