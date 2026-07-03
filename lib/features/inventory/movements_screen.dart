import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/movements_provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../data/providers/projects_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/movement_form_dialog.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  String _filterType = 'ALL'; // ALL, IN, OUT

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementsProvider>().fetchMovements();
      context.read<ProductsProvider>().fetchProducts();
      context.read<WarehousesProvider>().fetchWarehouses();
      context.read<ProjectsProvider>().fetchProjects();
    });
  }

  void _showMovementForm({String? prefilledCode}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MovementFormDialog(prefilledCode: prefilledCode),
      ),
    );

    if (result == true && mounted) {
      context.read<MovementsProvider>().fetchMovements();
      context.read<ProductsProvider>().fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          'Historial de Movimientos',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.qr_code_scanner_rounded,
                color: isDark ? Colors.white : const Color(0xFF2563EB),
                size: 20,
              ),
              tooltip: 'Escanear para mover',
              onPressed: () async {
                final String? code = await context.push('/scanner');
                if (code != null && context.mounted) {
                  _showMovementForm(prefilledCode: code);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMovementForm(),
        backgroundColor: isDark
            ? const Color(0xFF60A5FA)
            : const Color(0xFF1959AD),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(
          'Nuevo Movimiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              bottom: 12,
              top: 8,
              left: 16,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChip('Todos', 'ALL', Icons.list),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      'Solo Ingresos',
                      'IN',
                      Icons.arrow_downward,
                      Colors.green,
                    ),
                    _buildFilterChip(
                      'Solo Salidas',
                      'OUT',
                      Icons.arrow_upward,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<MovementsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredMovements = provider.movements.where((m) {
                  if (_filterType == 'ALL') return true;
                  return m.type == _filterType;
                }).toList();

                if (filteredMovements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay movimientos en esta categoría',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 80),
                  itemCount: filteredMovements.length,
                  itemBuilder: (context, index) {
                    final mov = filteredMovements[index];
                    final isEntry = mov.type == 'IN';

                    final productsProvider = context.read<ProductsProvider>();
                    final productName =
                        productsProvider.products
                            .where((p) => p.id == mov.productId)
                            .firstOrNull
                            ?.name ??
                        'Producto Desconocido';

                    DateTime parsedDate =
                        DateTime.tryParse(mov.date) ?? DateTime.now();
                    String formattedDate = DateFormat(
                      'dd/MM/yyyy • hh:mm a',
                    ).format(parsedDate);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isEntry
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEntry
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isEntry
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (mov.notes != null &&
                                      mov.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Nota: ${mov.notes}',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isEntry ? '+' : '-'}${mov.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: isEntry
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  isEntry ? 'ENTRADA' : 'SALIDA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isEntry
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                              padding: const EdgeInsets.only(left: 12),
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar Movimiento'),
                                    content: const Text(
                                      '¿Estás seguro de que deseas eliminar este movimiento? Se revertirá el stock de este producto.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  final success = await context
                                      .read<MovementsProvider>()
                                      .deleteMovement(mov);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              success
                                                  ? Icons.check_circle
                                                  : Icons.error,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                success
                                                    ? 'Movimiento eliminado y stock revertido.'
                                                    : 'No hay stock suficiente para revertir este movimiento.',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: success
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        margin: EdgeInsets.only(
                                          bottom:
                                              MediaQuery.of(
                                                context,
                                              ).size.height -
                                              150,
                                          left: 20,
                                          right: 20,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        elevation: 6,
                                      ),
                                    );
                                    if (success) {
                                      context
                                          .read<ProductsProvider>()
                                          .fetchProducts();
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String type,
    IconData icon, [
    Color? color,
  ]) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? Colors.blue.shade400
        : const Color(0xFF1959AD);
    final activeColor = color ?? defaultColor;

    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
