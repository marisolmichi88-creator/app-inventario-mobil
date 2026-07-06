import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/movement_model.dart';
import '../../data/initial_data.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/download_options_sheet.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/excel_service.dart';
import '../../features/auth/auth_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyLowStock = false;
  String? _filterCategoryId; // null = todas las categorías
  String? _filterWarehouseId; // null = stock global (todos los almacenes)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productsProvider = context.read<ProductsProvider>();
      final categoriesProvider = context.read<CategoriesProvider>();
      final movementsProvider = context.read<MovementsProvider>();
      final warehousesProvider = context.read<WarehousesProvider>();

      await productsProvider.fetchProducts();
      // Categorías para mostrar su nombre en el reporte exportado.
      await categoriesProvider.fetchCategories();
      // Para el stock por almacén calculado desde los movimientos (HU17).
      await movementsProvider.fetchMovements();
      await warehousesProvider.fetchWarehouses();

      // Ejecutar reparación/carga inicial de almacenes y monedas
      _runInitialDataRepair();
    });
  }

  Future<void> _runInitialDataRepair() async {
    final productsProvider = context.read<ProductsProvider>();
    final movementsProvider = context.read<MovementsProvider>();
    final warehousesProvider = context.read<WarehousesProvider>();
    final authProvider = context.read<AuthProvider>();

    // Corregir automáticamente cualquier stock duplicado por migraciones previas
    await _fixDoubledStocks();

    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'initial_data_repair_run_v6';
      final alreadyRun = prefs.getBool(key) ?? false;
      if (alreadyRun) return;

      debugPrint(
        'Iniciando reparación y migración de datos iniciales en la app (modo silencioso)...',
      );

      final products = productsProvider.products;
      final movements = movementsProvider.movements;
      final warehouses = warehousesProvider.warehouses;
      final currentUser = authProvider.currentUser;

      if (products.isEmpty || warehouses.isEmpty) {
        debugPrint('Reparación omitida: productos o almacenes vacíos.');
        return;
      }

      final userProfileId = currentUser?.id;
      if (userProfileId == null) {
        debugPrint('Reparación omitida: no hay un usuario autenticado.');
        return;
      }

      String normalize(String text) {
        return text
            .trim()
            .toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll(RegExp(r'\s+'), ' ');
      }

      final Map<String, String> warehouseMap = {};
      for (final w in warehouses) {
        warehouseMap[normalize(w.name)] = w.id!;
      }

      int currenciesUpdated = 0;
      int movementsCreated = 0;

      for (final entry in initialProductData.entries) {
        final code = entry.key;
        final data = entry.value;

        final prodList = products.where((p) => p.code == code).toList();
        if (prodList.isEmpty) continue;
        final prod = prodList.first;

        // A. Corrección de Moneda y Almacén
        final targetCurrency = data['currency'] ?? 'PEN';
        final rawWarehouseName = data['warehouse'] ?? '';
        final warehouseId = warehouseMap[normalize(rawWarehouseName)];

        if (prod.currency != targetCurrency || prod.warehouseId != warehouseId) {
          final updatedProduct = ProductModel(
            id: prod.id,
            code: prod.code,
            serialNumber: prod.serialNumber,
            name: prod.name,
            categoryId: prod.categoryId,
            warehouseId: warehouseId,
            stock: prod.stock,
            minStock: prod.minStock,
            unit: prod.unit,
            price: prod.price,
            currency: targetCurrency,
            isActive: prod.isActive,
          );
          await productsProvider.updateProduct(updatedProduct);
          currenciesUpdated++;
        }

        // B. Registro de Movimiento Inicial
        final int stockQuantity = prod.stock;
        if (stockQuantity > 0) {
          final rawWarehouseName = data['warehouse'] ?? '';
          final warehouseId = warehouseMap[normalize(rawWarehouseName)];

          if (warehouseId == null) {
            debugPrint(
              'Error: Almacén $rawWarehouseName no encontrado en BD para $code',
            );
            continue;
          }

          final hasMovement = movements.any(
            (m) =>
                m.productId == prod.id &&
                m.warehouseId == warehouseId &&
                m.type == 'IN',
          );

          if (!hasMovement) {
            final dateStr = data['date']?.isNotEmpty == true
                ? data['date']!
                : DateTime.now().toIso8601String().split('T')[0];

            final newMovement = MovementModel(
              productId: prod.id!,
              warehouseId: warehouseId,
              projectId: null,
              userId: userProfileId,
              type: 'IN',
              quantity: stockQuantity,
              date: dateStr,
              notes: 'Carga inicial migrada desde Excel',
            );

            // Silencioso, sin enviar notificaciones masivas push al celular, y sin duplicar stock
            await movementsProvider.registerMovement(
              newMovement,
              showNotification: false,
              updateProductStock: false,
            );
            movementsCreated++;
          }
        }
      }

      debugPrint(
        'Reparación finalizada silenciosamente. Monedas actualizadas: $currenciesUpdated. Movimientos creados: $movementsCreated.',
      );
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('Error en reparación de datos iniciales: $e');
    }
  }

  Future<void> _fixDoubledStocks() async {
    final productsProvider = context.read<ProductsProvider>();
    final movementsProvider = context.read<MovementsProvider>();
    try {
      final prefs = await SharedPreferences.getInstance();
      const fixKey = 'fix_doubled_stocks_run_v3';
      final alreadyRun = prefs.getBool(fixKey) ?? false;
      if (alreadyRun) return;

      debugPrint('Iniciando corrección de stocks duplicados...');
      final products = productsProvider.products;
      final movements = movementsProvider.movements;

      int correctedCount = 0;
      for (final prod in products) {
        final initialMovs = movements.where(
          (m) =>
              m.productId == prod.id &&
              m.type == 'IN' &&
              m.notes == 'Carga inicial migrada desde Excel',
        ).toList();

        if (initialMovs.isNotEmpty) {
          final correctStock = initialMovs.first.quantity;
          if (prod.stock != correctStock) {
            final updatedProduct = ProductModel(
              id: prod.id,
              code: prod.code,
              serialNumber: prod.serialNumber,
              name: prod.name,
              categoryId: prod.categoryId,
              warehouseId: prod.warehouseId,
              stock: correctStock,
              minStock: prod.minStock,
              unit: prod.unit,
              price: prod.price,
              currency: prod.currency,
              isActive: prod.isActive,
            );
            await productsProvider.updateProduct(updatedProduct);
            correctedCount++;
          }
        }
      }
      debugPrint('Corrección de stocks finalizada. Productos corregidos: $correctedCount');
      await prefs.setBool(fixKey, true);
    } catch (e) {
      debugPrint('Error al corregir stocks duplicados: $e');
    }
  }

  /// Stock por almacén calculado al vuelo desde los movimientos (HU17):
  /// suma de entradas menos salidas de cada producto en ese almacén.
  Map<String, int> _stockForWarehouse(String warehouseId) {
    final movements = context.read<MovementsProvider>().movements;
    final Map<String, int> result = {};
    for (final m in movements) {
      if (m.warehouseId != warehouseId) continue;
      final delta = m.type == 'IN' ? m.quantity : -m.quantity;
      result[m.productId] = (result[m.productId] ?? 0) + delta;
    }
    return result;
  }

  void _showDownloadOptions() {
    final productsProvider = context.read<ProductsProvider>();
    final categoriesProvider = context.read<CategoriesProvider>();

    DownloadOptionsSheet.show(
      context,
      title: 'Descargar Inventario',
      subtitle: 'Exporta el catálogo de productos',
      options: [
        DownloadOption(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exportar PDF',
          subtitle: 'Estado actual del stock en PDF',
          color: const Color(0xFFDC2626),
          onTap: () => PdfService.generateInventoryReport(
            productsProvider.products,
            categoriesProvider.categories,
          ),
        ),
        DownloadOption(
          icon: Icons.table_chart_rounded,
          title: 'Exportar Excel',
          subtitle: 'Archivo .xlsx para hojas de cálculo',
          color: const Color(0xFF16A34A),
          onTap: () => ExcelService.exportInventory(
            productsProvider.products,
            categoriesProvider.categories,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text(
            '¿Estás seguro?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('¿Desea eliminar el producto "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx); // Cerrar diálogo
                Navigator.pop(context); // Cerrar BottomSheet

                final deleted = await context
                    .read<ProductsProvider>()
                    .deleteProduct(product.id!);

                if (context.mounted) {
                  if (deleted) {
                    CustomSnackBar.showSuccess(context, 'Producto eliminado');
                  } else {
                    CustomSnackBar.showWarning(context, 'Producto desactivado');
                  }
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductForm([ProductModel? product]) {
    final isEditing = product != null;
    final codeController = TextEditingController(text: product?.code ?? '');
    final serialNumberController = TextEditingController(
      text: product?.serialNumber ?? '',
    );
    final nameController = TextEditingController(text: product?.name ?? '');
    final stockController = TextEditingController(
      text: product?.stock.toString() ?? '',
    );
    final minStockController = TextEditingController(
      text: product?.minStock.toString() ?? '5',
    );
    final unitController = TextEditingController(text: product?.unit ?? 'UND');
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentUser = context.read<AuthProvider>().currentUser;
        final isAdmin = currentUser?.role == 'admin';
        final categories = context.read<CategoriesProvider>().categories;
        final warehouses = context
            .read<WarehousesProvider>()
            .warehouses
            .where((w) => w.isActive)
            .toList();
        String selectedCurrency = product?.currency ?? 'PEN';
        String? selectedCategoryId = product?.categoryId;
        String? selectedWarehouseId = product?.warehouseId;
        if (selectedWarehouseId != null &&
            !warehouses.any((w) => w.id == selectedWarehouseId)) {
          selectedWarehouseId = null;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                            isEditing ? 'Editar Producto' : 'Nuevo Producto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              if (isEditing && isAdmin)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteProduct(context, product),
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
                        controller: codeController,
                        label: 'Código / SKU',
                        hint: 'Ej. PROD-0001',
                        icon: Icons.qr_code_2,
                        isDark: isDark,
                        enabled: isAdmin,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: serialNumberController,
                        label: 'Número de Serie (Opcional)',
                        hint: 'Ej. SN-123456',
                        icon: Icons.tag,
                        isDark: isDark,
                        enabled: isAdmin,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: nameController,
                        label: 'Nombre del Producto',
                        hint: 'Ej. Inversor Solar 3000W',
                        icon: Icons.local_offer_outlined,
                        isDark: isDark,
                        enabled: isAdmin,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue:
                            categories.any((c) => c.id == selectedCategoryId)
                            ? selectedCategoryId
                            : null,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Categoría (Opcional)',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.category_outlined,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black87,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        hint: Text(
                          'Sin categoría',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isAdmin
                            ? (val) => setState(() => selectedCategoryId = val)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: stockController,
                              label: isEditing
                                  ? 'Stock Actual'
                                  : 'Stock Inicial',
                              hint: '0',
                              icon: Icons.inventory_2_outlined,
                              isNumber: true,
                              isDark: isDark,
                              enabled: isAdmin && !isEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              controller: minStockController,
                              label: 'Stock Mínimo',
                              hint: '5',
                              icon: Icons.warning_amber_rounded,
                              isNumber: true,
                              isDark: isDark,
                              enabled: isAdmin,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedWarehouseId,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Almacén',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.storefront_outlined,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black87,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        hint: Text(
                          'Seleccionar Almacén',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        validator: (val) {
                          if (val == null) return 'Selecciona un almacén';
                          return null;
                        },
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem<String>(
                                value: w.id,
                                child: Text(
                                  w.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isAdmin
                            ? (val) => setState(() => selectedWarehouseId = val)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: unitController,
                              label: 'Unidad (ej. Kg, Lt)',
                              hint: 'Ej. UND',
                              icon: Icons.straighten,
                              isDark: isDark,
                              enabled: isAdmin,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCurrency,
                              dropdownColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              decoration: InputDecoration(
                                labelText: 'Moneda',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PEN',
                                  child: Text('Soles'),
                                ),
                                DropdownMenuItem(
                                  value: 'USD',
                                  child: Text('Dólares'),
                                ),
                              ],
                              onChanged: isAdmin
                                  ? (val) {
                                      if (val != null) {
                                        setState(() => selectedCurrency = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: priceController,
                        label: 'Precio',
                        hint: '0.00',
                        icon: Icons.payments_outlined,
                        isNumber: true,
                        isDark: isDark,
                        enabled: isAdmin,
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Stock por Almacén',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: warehouses.map((wh) {
                              final movements = context
                                  .read<MovementsProvider>()
                                  .movements;
                              int stockInWh = 0;
                              for (final m in movements) {
                                if (m.productId == product.id &&
                                    m.warehouseId == wh.id) {
                                  final delta = m.type == 'IN'
                                      ? m.quantity
                                      : -m.quantity;
                                  stockInWh += delta;
                                }
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      wh.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '$stockInWh ${product.unit?.isNotEmpty == true ? product.unit : 'UND'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: stockInWh > 0
                                            ? (isDark
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFF1959AD))
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isAdmin ? 'Cancelar' : 'Cerrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF1959AD),
                                ),
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final newProduct = ProductModel(
                                      id: product?.id,
                                      code: codeController.text.trim(),
                                      serialNumber: serialNumberController.text
                                          .trim()
                                          .isEmpty
                                          ? null
                                          : serialNumberController.text.trim(),
                                      name: nameController.text.trim(),
                                      categoryId: selectedCategoryId,
                                      warehouseId: selectedWarehouseId,
                                      stock:
                                          int.tryParse(stockController.text) ??
                                          0,
                                      minStock:
                                          int.tryParse(
                                            minStockController.text,
                                          ) ??
                                          0,
                                      unit: unitController.text.trim(),
                                      price:
                                          double.tryParse(
                                            priceController.text,
                                          ) ??
                                          0.0,
                                      currency: selectedCurrency,
                                      isActive: product?.isActive ?? true,
                                    );

                                    final productsProvider = context.read<ProductsProvider>();
                                    final authProvider = context.read<AuthProvider>();
                                    final movementsProvider = context.read<MovementsProvider>();

                                    if (isEditing) {
                                      await productsProvider.updateProduct(newProduct);
                                    } else {
                                      final prodId =
                                          newProduct.id ?? const Uuid().v4();
                                      final finalProduct = ProductModel(
                                        id: prodId,
                                        code: newProduct.code,
                                        serialNumber: newProduct.serialNumber,
                                        name: newProduct.name,
                                        categoryId: newProduct.categoryId,
                                        warehouseId: newProduct.warehouseId,
                                        stock: newProduct.stock,
                                        minStock: newProduct.minStock,
                                        unit: newProduct.unit,
                                        price: newProduct.price,
                                        currency: newProduct.currency,
                                        isActive: newProduct.isActive,
                                      );

                                      await productsProvider.addProduct(
                                        finalProduct,
                                      );

                                      if (finalProduct.stock > 0 &&
                                          selectedWarehouseId != null) {
                                        final userProfileId = authProvider
                                            .currentUser
                                            ?.id;
                                        if (userProfileId != null) {
                                          final initialMovement = MovementModel(
                                            productId: prodId,
                                            warehouseId:
                                                selectedWarehouseId!,
                                            projectId: null,
                                            userId: userProfileId,
                                            type: 'IN',
                                            quantity: finalProduct.stock,
                                            date: DateTime.now()
                                                .toIso8601String()
                                                .split('T')[0],
                                            notes:
                                                'Carga inicial de inventario',
                                          );
                                          await movementsProvider
                                              .registerMovement(
                                                initialMovement,
                                              );
                                        }
                                      }
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF1959AD),
                                  foregroundColor: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.save_rounded, size: 20),
                                label: const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isNumber = false,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      validator: (val) {
        if (!enabled) return null;
        if (val == null || val.isEmpty) return 'Requerido';
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
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : Colors.black87,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }


  void _showFilterSheet() {
    final categories = context.read<CategoriesProvider>().categories;
    final warehouses = context
        .read<WarehousesProvider>()
        .warehouses
        .where((w) => w.isActive)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    // Valores temporales para guardar la selección antes de aplicar
    String? tmpCategory = _filterCategoryId;
    String? tmpWarehouse = _filterWarehouseId;
    bool tmpLowStock = _showOnlyLowStock;

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.black54,
              fontSize: 14),
          prefixIcon: Icon(icon,
              color: isDark ? Colors.grey.shade400 : Colors.black87, size: 20),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    24,
                left: 24,
                right: 24,
                top: 16,
              ),
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
                    const SizedBox(height: 20),
                    Text(
                      'Filtrar productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selector de Almacén
                    DropdownButtonFormField<String>(
                      initialValue: tmpWarehouse,
                      isExpanded: true,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      decoration:
                          deco('Almacén', Icons.storefront_outlined),
                      hint: const Text('Todos', style: TextStyle(fontSize: 14)),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('Todos los almacenes')),
                        ...warehouses.map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)))),
                      ],
                      onChanged: (v) => setSheet(() => tmpWarehouse = v),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Categoría
                    DropdownButtonFormField<String>(
                      initialValue: tmpCategory,
                      isExpanded: true,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      decoration:
                          deco('Categoría', Icons.local_offer_outlined),
                      hint: const Text('Todas', style: TextStyle(fontSize: 14)),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('Todas las categorías')),
                        ...categories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)))),
                      ],
                      onChanged: (v) => setSheet(() => tmpCategory = v),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Alerta de Stock
                    DropdownButtonFormField<bool>(
                      initialValue: tmpLowStock,
                      isExpanded: true,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      decoration:
                          deco('Estado de Stock', Icons.warning_amber_rounded),
                      items: const [
                        DropdownMenuItem<bool>(
                            value: false, child: Text('Todos los niveles')),
                        DropdownMenuItem<bool>(
                            value: true, child: Text('Solo Stock Crítico')),
                      ],
                      onChanged: (v) => setSheet(() => tmpLowStock = v ?? false),
                    ),
                    const SizedBox(height: 24),

                    // Botones de Acción
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _filterCategoryId = null;
                                _filterWarehouseId = null;
                                _showOnlyLowStock = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Limpiar Filtros',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _filterCategoryId = tmpCategory;
                                _filterWarehouseId = tmpWarehouse;
                                _showOnlyLowStock = tmpLowStock;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Aplicar Filtros',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          'Catálogo de Productos',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: isDark ? Colors.white : const Color(0xFF2563EB),
                size: 20,
              ),
              tooltip: 'Descargar / Exportar',
              onPressed: _showDownloadOptions,
            ),
          ),
          const SizedBox(width: 8),
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
              tooltip: 'Escanear Código',
              onPressed: () {
                context.push('/scanner');
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          context.watch<AuthProvider>().currentUser?.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => _showProductForm(),
              backgroundColor: isDark
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF1959AD),
              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              elevation: 1,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nuevo Producto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }


          // Rebuild al cambiar movimientos (para el stock por almacén - HU17)
          context.watch<MovementsProvider>();
          final warehouses = context
              .watch<WarehousesProvider>()
              .warehouses
              .where((w) => w.isActive)
              .toList();

          // Si hay un almacén seleccionado, calcular el stock por almacén.
          final Map<String, int>? whStock = _filterWarehouseId == null
              ? null
              : _stockForWarehouse(_filterWarehouseId!);

          int displayStock(ProductModel p) {
            if (_filterWarehouseId == null) return p.stock;
            if (whStock != null && whStock.containsKey(p.id)) {
              return whStock[p.id]!;
            }
            if (p.warehouseId == _filterWarehouseId) {
              return p.stock;
            }
            return 0;
          }
          final selectedWarehouseName = _filterWarehouseId == null
              ? null
              : warehouses
                    .where((w) => w.id == _filterWarehouseId)
                    .map((w) => w.name)
                    .firstOrNull;

          var filteredList = provider.products.where((p) {
            final matchesQuery =
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.code.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory =
                _filterCategoryId == null || p.categoryId == _filterCategoryId;
            // Con filtro de almacén: solo productos con movimientos en ese almacén o que pertenezcan a él por defecto.
            if (_filterWarehouseId != null) {
              final belongsToWarehouse = p.warehouseId == _filterWarehouseId;
              final hasMovements = whStock != null && whStock.containsKey(p.id);
              if (!belongsToWarehouse && !hasMovements) return false;
            }
            final ds = displayStock(p);
            final matchesLowStock = !_showOnlyLowStock || ds <= p.minStock;
            return matchesQuery && matchesCategory && matchesLowStock;
          }).toList();

          return Column(
            children: [
              // Search Bar & Filter Button row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.card(isDark: isDark),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón de Filtros
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.card(isDark: isDark),
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(12),
                        icon: Icon(
                          Icons.tune_rounded,
                          color: (_filterCategoryId != null || _filterWarehouseId != null || _showOnlyLowStock)
                              ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD))
                              : Colors.grey,
                        ),
                        onPressed: _showFilterSheet,
                        tooltip: 'Filtrar Productos',
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E40AF).withValues(alpha: 0.5)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: isDark
                              ? Colors.blue.shade300
                              : const Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredList.length}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedWarehouseName != null
                                  ? 'En $selectedWarehouseName'
                                  : 'Productos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                'Stock Crítico',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _showOnlyLowStock,
                                onChanged: (val) =>
                                    setState(() => _showOnlyLowStock = val),
                                activeThumbColor: Colors.white,
                                activeTrackColor: isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF1959AD),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final prod = filteredList[index];
                          final stockValue = displayStock(prod);
                          final isLowStock = stockValue <= prod.minStock;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppShadows.card(isDark: isDark),
                              border: isLowStock
                                  ? Border.all(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: InkWell(
                              onTap: () => _showProductForm(prod),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(
                                                0xFF60A5FA,
                                              ).withValues(alpha: 0.15)
                                            : const Color(
                                                0xFF1959AD,
                                              ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF1959AD),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prod.name.toUpperCase(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'SKU: ${prod.code}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${prod.currency == 'USD' ? '\$' : 'S/.'} ${prod.price.toStringAsFixed(2)} / ${prod.unit?.isNotEmpty == true ? prod.unit : 'UND'}',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFF1959AD),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLowStock
                                                ? (isDark
                                                      ? const Color(
                                                          0xFFDC2626,
                                                        ).withValues(alpha: 0.2)
                                                      : const Color(0xFFFEE2E2))
                                                : (isDark
                                                      ? const Color(
                                                          0xFF16A34A,
                                                        ).withValues(alpha: 0.2)
                                                      : const Color(
                                                          0xFFDCFCE7,
                                                        )),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$stockValue',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: isLowStock
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFFF87171,
                                                          )
                                                        : const Color(
                                                            0xFFDC2626,
                                                          ))
                                                  : (isDark
                                                        ? const Color(
                                                            0xFF4ADE80,
                                                          )
                                                        : const Color(
                                                            0xFF16A34A,
                                                          )),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SizedBox(
                                          width: 72,
                                          child: Text(
                                            selectedWarehouseName ?? 'Stock',
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ],
                                ),
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
