import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/models/product_model.dart';
import '../../core/widgets/custom_snackbar.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehousesProvider>().fetchWarehouses();
      // El detalle de cada almacén lista productos desde este provider.
      if (context.read<ProductsProvider>().products.isEmpty) {
        context.read<ProductsProvider>().fetchProducts();
      }
    });
  }

  /// Indicador compacto para las cifras del almacén.
  Widget _statChip({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsFooter(BuildContext context, WarehouseStats stats, bool isLoading) {
    if (isLoading && stats.productCount == 0) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Contando productos...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    if (stats.productCount == 0) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              'Sin productos asignados',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statChip(
          context: context,
          icon: Icons.inventory_2_outlined,
          value: '${stats.productCount}',
          label: stats.productCount == 1 ? 'producto' : 'productos',
          color: const Color(0xFF3B82F6),
        ),
        _statChip(
          context: context,
          icon: Icons.layers_outlined,
          value: _formatNumber(stats.totalUnits),
          label: stats.totalUnits == 1 ? 'unidad' : 'unidades',
          color: const Color(0xFF10B981),
        ),
        if (stats.lowStockCount > 0)
          _statChip(
            context: context,
            icon: Icons.warning_amber_rounded,
            value: '${stats.lowStockCount}',
            label: 'bajo stock',
            color: const Color(0xFFEF4444),
          ),
      ],
    );
  }

  static String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Lista los productos guardados en un almacén, sin salir de esta pantalla.
  void _showWarehouseProducts(WarehouseModel warehouse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                warehouse.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Productos en este almacén',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  Expanded(
                    child: Consumer<ProductsProvider>(
                      builder: (context, productsProvider, _) {
                        if (productsProvider.isLoading &&
                            productsProvider.products.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final items = productsProvider.products
                            .where((p) => p.warehouseId == warehouse.id && p.isActive)
                            .toList()
                          ..sort((a, b) => a.name.compareTo(b.name));

                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Este almacén no tiene productos',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _productTile(context, items[index], isDark),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _productTile(BuildContext context, ProductModel product, bool isDark) {
    final isLow = product.stock <= product.minStock;
    final stockColor = isLow ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  product.internalQr ?? product.code,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.stock}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: stockColor,
                  ),
                ),
                Text(
                  product.unit ?? 'UND',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: (val) {
        if (!enabled) return null;
        if (maxLines == 1 && (val == null || val.isEmpty)) return 'Requerido';
        return null;
      },
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.black54,
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade400 : Colors.black87, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }

  Future<void> _confirmDeleteWarehouse(
    BuildContext sheetContext,
    WarehouseModel warehouse,
  ) async {
    final stats = context.read<WarehousesProvider>().statsFor(warehouse.id);

    // Con productos dentro ni se pregunta: se ofrece desactivarlo, que es lo
    // que la persona realmente quiere en ese caso.
    if (stats.productCount > 0) {
      CustomSnackBar.showWarning(
        context,
        'No se puede eliminar: tiene ${stats.productCount} '
        '${stats.productCount == 1 ? "producto" : "productos"}. '
        'Muévelos a otro almacén o desactívalo con el interruptor.',
      );
      return;
    }

    // Se captura antes del await: después, sheetContext puede haberse ido.
    final sheetNavigator = Navigator.of(sheetContext);

    final confirmed = await showAdminDeleteConfirm(
      sheetContext,
      title: '¿Eliminar este almacén?',
      itemName: warehouse.name,
      warning: 'Se borra de forma permanente y no se puede recuperar.\n\n'
          'Si solo quieres dejar de usarlo, cancela y usa el interruptor '
          'para desactivarlo: así conservas su historial.',
    );
    if (!confirmed || !mounted) return;

    sheetNavigator.pop();

    try {
      final deleted =
          await context.read<WarehousesProvider>().deleteWarehouse(warehouse.id!);
      if (!mounted) return;
      if (deleted) {
        CustomSnackBar.showSuccess(context, 'Almacén eliminado');
      } else {
        CustomSnackBar.showWarning(
          context,
          'No se puede eliminar: tiene productos o movimientos asociados.',
        );
      }
    } catch (_) {
      if (mounted) CustomSnackBar.showError(context, 'Error al eliminar');
    }
  }

  void _showWarehouseForm([WarehouseModel? warehouse]) {
    final isEditing = warehouse != null;
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final locationController = TextEditingController(text: warehouse?.location ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Editar Almacén' : 'Nuevo Almacén',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing)
                            adminDeleteButton(
                              tooltip: 'Eliminar almacén',
                              onPressed: () =>
                                  _confirmDeleteWarehouse(context, warehouse),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    controller: nameController,
                    label: 'Nombre del Almacén',
                    hint: 'Ej. Bodega Principal',
                    icon: Icons.warehouse_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: locationController,
                    label: 'Ubicación / Detalles (Opcional)',
                    hint: 'Ej. Av. Principal 123, Sector Norte',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newWarehouse = WarehouseModel(
                                id: warehouse?.id,
                                name: nameController.text.trim(),
                                location: locationController.text.trim(),
                                isActive: warehouse?.isActive ?? true,
                              );
                              
                              if (isEditing) {
                                context.read<WarehousesProvider>().updateWarehouse(newWarehouse);
                              } else {
                                context.read<WarehousesProvider>().addWarehouse(newWarehouse);
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Gestión de Almacenes'),
      floatingActionButton: adminFab(
        context: context,
        onPressed: () => _showWarehouseForm(),
        label: 'Nuevo Almacén',
      ),
      body: Consumer<WarehousesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.warehouses.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.warehouse_outlined,
              title: 'No hay almacenes registrados',
              subtitle: 'Agrega almacenes para organizar tu inventario.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.warehouses.length,
            itemBuilder: (context, index) {
              final wh = provider.warehouses[index];
              final stats = provider.statsFor(wh.id);

              return AdminListCard(
                icon: Icons.warehouse_outlined,
                iconColor: wh.isActive ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                iconBackground: wh.isActive
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                title: wh.name,
                subtitle: wh.location?.isNotEmpty == true ? wh.location! : 'Sin ubicación',
                onTap: stats.productCount > 0 ? () => _showWarehouseProducts(wh) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    adminEditButton(onPressed: () => _showWarehouseForm(wh)),
                    adminStatusSwitch(
                      value: wh.isActive,
                      onChanged: (val) => provider.toggleWarehouseStatus(wh.id!, !val),
                    ),
                  ],
                ),
                footer: _buildStatsFooter(context, stats, provider.isLoadingStats),
              );
            },
          );
        },
      ),
    );
  }
}
