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

  void _showMovementForm({String? prefilledCode}) {
    showDialog(
      context: context,
      builder: (context) => MovementFormDialog(prefilledCode: prefilledCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Movimientos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear para mover',
            onPressed: () async {
              final String? code = await context.push('/scanner');
              if (code != null && context.mounted) {
                _showMovementForm(prefilledCode: code);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMovementForm(),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Nuevo Movimiento'),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1959AD).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'ALL', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Solo Ingresos',
                    'IN',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Solo Salidas',
                    'OUT',
                    Icons.arrow_upward,
                    Colors.redAccent,
                  ),
                ],
              ),
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isEntry
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEntry
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isEntry
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          title: Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (mov.notes != null &&
                                  mov.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Nota: ${mov.notes}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isEntry ? '+' : '-'}${mov.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: isEntry
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              Text(
                                isEntry ? 'ENTRADA' : 'SALIDA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isEntry ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
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
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        color: isSelected
            ? Colors.white
            : (color ?? Theme.of(context).primaryColor),
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      selectedColor: color ?? Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _filterType = type;
          });
        }
      },
    );
  }
}
