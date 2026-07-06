import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/providers/movements_provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../data/providers/projects_provider.dart';
import '../../data/providers/users_provider.dart';
import '../../data/models/movement_model.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/excel_service.dart';
import 'package:intl/intl.dart';
import 'widgets/movement_form_dialog.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/download_options_sheet.dart';

class MovementsScreen extends StatefulWidget {
  final bool showForm;
  const MovementsScreen({super.key, this.showForm = false});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  String _filterType = 'ALL'; // ALL, IN, OUT
  String? _filterProductId;
  String? _filterWarehouseId;
  String? _filterUserId;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  bool get _hasAdvancedFilters =>
      _filterProductId != null ||
      _filterWarehouseId != null ||
      _filterUserId != null ||
      _filterStart != null ||
      _filterEnd != null;

  List<MovementModel> _applyFilters(List<MovementModel> movements) {
    return movements.where((m) {
      if (_filterType != 'ALL' && m.type != _filterType) return false;
      if (_filterProductId != null && m.productId != _filterProductId) {
        return false;
      }
      if (_filterWarehouseId != null && m.warehouseId != _filterWarehouseId) {
        return false;
      }
      if (_filterUserId != null && m.userId != _filterUserId) return false;
      final d = DateTime.tryParse(m.date);
      if (_filterStart != null && (d == null || d.isBefore(_filterStart!))) {
        return false;
      }
      if (_filterEnd != null && (d == null || d.isAfter(_filterEnd!))) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementsProvider>().fetchMovements();
      context.read<ProductsProvider>().fetchProducts();
      context.read<WarehousesProvider>().fetchWarehouses();
      context.read<ProjectsProvider>().fetchProjects();
      // Para que los reportes muestren el nombre del usuario (solo admin).
      final user = context.read<AuthProvider>().currentUser;
      if (user?.role == 'admin') {
        context.read<UsersProvider>().fetchUsers();
      }
      if (widget.showForm) {
        _showMovementForm();
      }
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

  void _showFilterSheet() {
    final products = context.read<ProductsProvider>().products;
    final warehouses = context.read<WarehousesProvider>().warehouses;
    final users = context.read<UsersProvider>().users;
    final isAdmin =
        context.read<AuthProvider>().currentUser?.role == 'admin';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    // Valores temporales dentro del panel
    String? tmpProduct = _filterProductId;
    String? tmpWarehouse = _filterWarehouseId;
    String? tmpUser = _filterUserId;
    DateTime? tmpStart = _filterStart;
    DateTime? tmpEnd = _filterEnd;

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
            String dateLabel() {
              if (tmpStart == null && tmpEnd == null) return 'Cualquier fecha';
              final f = DateFormat('dd/MM/yyyy');
              final s = tmpStart != null ? f.format(tmpStart!) : '...';
              final e = tmpEnd != null ? f.format(tmpEnd!) : '...';
              return '$s  →  $e';
            }

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
                      'Filtrar movimientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Rango de fechas
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: tmpStart != null && tmpEnd != null
                              ? DateTimeRange(start: tmpStart!, end: tmpEnd!)
                              : null,
                        );
                        if (range != null) {
                          setSheet(() {
                            tmpStart = DateTime(range.start.year,
                                range.start.month, range.start.day);
                            tmpEnd = DateTime(range.end.year, range.end.month,
                                range.end.day, 23, 59, 59);
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: deco('Rango de fechas', Icons.date_range_outlined),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateLabel(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(ctx).colorScheme.onSurface,
                              ),
                            ),
                            if (tmpStart != null || tmpEnd != null)
                              GestureDetector(
                                onTap: () =>
                                    setSheet(() {
                                  tmpStart = null;
                                  tmpEnd = null;
                                }),
                                child: const Icon(Icons.clear,
                                    size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tmpProduct,
                      isExpanded: true,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      decoration:
                          deco('Producto', Icons.inventory_2_outlined),
                      hint: const Text('Todos', style: TextStyle(fontSize: 14)),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('Todos')),
                        ...products.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)))),
                      ],
                      onChanged: (v) => setSheet(() => tmpProduct = v),
                    ),
                    const SizedBox(height: 16),
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
                            value: null, child: Text('Todos')),
                        ...warehouses.map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)))),
                      ],
                      onChanged: (v) => setSheet(() => tmpWarehouse = v),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: tmpUser,
                        isExpanded: true,
                        dropdownColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: deco('Usuario', Icons.person_outline),
                        hint:
                            const Text('Todos', style: TextStyle(fontSize: 14)),
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, child: Text('Todos')),
                          ...users.map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(u.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14)))),
                        ],
                        onChanged: (v) => setSheet(() => tmpUser = v),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _filterProductId = null;
                                _filterWarehouseId = null;
                                _filterUserId = null;
                                _filterStart = null;
                                _filterEnd = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Limpiar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _filterProductId = tmpProduct;
                                _filterWarehouseId = tmpWarehouse;
                                _filterUserId = tmpUser;
                                _filterStart = tmpStart;
                                _filterEnd = tmpEnd;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Aplicar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showDownloadOptions() {
    final productsProvider = context.read<ProductsProvider>();
    final warehousesProvider = context.read<WarehousesProvider>();
    final projectsProvider = context.read<ProjectsProvider>();
    final usersProvider = context.read<UsersProvider>();

    // Exporta respetando los filtros activos (tipo, fecha, producto, etc.)
    final movements = _applyFilters(context.read<MovementsProvider>().movements);
    final subtitle = _hasAdvancedFilters || _filterType != 'ALL'
        ? 'Se exportará el resultado filtrado (${movements.length})'
        : 'Historial completo (${movements.length})';

    DownloadOptionsSheet.show(
      context,
      title: 'Descargar Movimientos',
      subtitle: subtitle,
      options: [
        DownloadOption(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exportar PDF',
          subtitle: 'Documento para imprimir',
          color: const Color(0xFFDC2626),
          onTap: () => PdfService.generateAndPrintMovementsReport(
            movements,
            productsProvider.products,
          ),
        ),
        DownloadOption(
          icon: Icons.table_chart_rounded,
          title: 'Exportar Excel',
          subtitle: 'Archivo .xlsx para hojas de cálculo',
          color: const Color(0xFF16A34A),
          onTap: () => ExcelService.exportMovements(
            movements,
            productsProvider.products,
            warehousesProvider.warehouses,
            projectsProvider.projects,
            usersProvider.users,
          ),
        ),
        DownloadOption(
          icon: Icons.verified_user_outlined,
          title: 'Reporte de Auditoría',
          subtitle: 'Elegir semana / mes / rango (solo lectura)',
          color: const Color(0xFF7C3AED),
          onTap: () async => context.push('/reports'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == 'admin';
    // Mantiene las suscripciones para que la pantalla se refresque al cambiar
    // movimientos o productos (igual que antes; la lista usa su propio Consumer).
    context.watch<MovementsProvider>();
    context.watch<ProductsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

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
          if (user?.role == 'admin') ...[
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
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Limpiar Historial',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Limpiar Historial'),
                      content: const Text(
                        '¿Estás seguro de que deseas eliminar TODOS los movimientos del historial? Esto no modificará el stock actual de los productos, solo limpiará el log de movimientos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Limpiar todo',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final success = await context
                        .read<MovementsProvider>()
                        .clearAllMovements();
                    if (context.mounted) {
                      if (success) {
                        CustomSnackBar.showSuccess(
                          context,
                          'Historial limpiado completamente',
                        );
                      } else {
                        CustomSnackBar.showError(
                          context,
                          'Error al limpiar historial',
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
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
        backgroundColor: actionColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 1,
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
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', 'ALL', Icons.list),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Ingresos',
                          'IN',
                          Icons.arrow_downward,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Salidas',
                          'OUT',
                          Icons.arrow_upward,
                          Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _hasAdvancedFilters
                        ? actionColor
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: _hasAdvancedFilters
                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                          : (isDark ? Colors.white : const Color(0xFF2563EB)),
                      size: 20,
                    ),
                    tooltip: 'Filtros Avanzados',
                    onPressed: _showFilterSheet,
                  ),
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

                final filteredMovements = _applyFilters(provider.movements);

                if (filteredMovements.isEmpty) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppShadows.card(isDark: isDark),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: actionColor,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Sin movimientos registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron registros de entrada o salida para este filtro en el historial de movimientos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
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
                        boxShadow: AppShadows.card(isDark: isDark),
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
                                    ? (isDark
                                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                        : const Color(0xFFDCFCE7))
                                    : (isDark
                                        ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                                        : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEntry
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isEntry
                                    ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                    : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
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
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      height: 1.25,
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
                            if (isAdmin)
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
                                      if (success) {
                                        CustomSnackBar.showSuccess(context, 'Movimiento eliminado');
                                        context.read<ProductsProvider>().fetchProducts();
                                      } else {
                                        CustomSnackBar.showError(context, 'Reversión fallida');
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
              ? AppShadows.tinted(activeColor, alpha: 0.12)
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
