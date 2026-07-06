import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/widgets/admin_ui.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/download_options_sheet.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/excel_service.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/project_model.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/movements_provider.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../data/providers/projects_provider.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/providers/users_provider.dart';

/// Sección de Reportes (HU20 - accesos directos). Reúne los reportes de
/// inventario (HU21), movimientos con rango (HU22), por proyecto (HU23)
/// y auditoría de solo lectura por periodo (HU24).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts();
      context.read<MovementsProvider>().fetchMovements();
      context.read<WarehousesProvider>().fetchWarehouses();
      context.read<ProjectsProvider>().fetchProjects();
      context.read<CategoriesProvider>().fetchCategories();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  // ---------- Selector de periodo (semana / mes / todos / rango) ----------
  Future<({DateTime? start, DateTime? end, String label})?>
      _choosePeriod() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    return showModalBottomSheet<({DateTime? start, DateTime? end, String label})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget tile(IconData icon, String title, String subtitle,
            VoidCallback onTap) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(ctx).colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Elige el periodo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(ctx).colorScheme.onSurface)),
              const SizedBox(height: 16),
              tile(Icons.today_rounded, 'Última semana', 'Últimos 7 días', () {
                Navigator.pop(ctx, (
                  start: now.subtract(const Duration(days: 7)),
                  end: now,
                  label: 'Última semana',
                ));
              }),
              tile(Icons.calendar_month_rounded, 'Último mes', 'Últimos 30 días',
                  () {
                Navigator.pop(ctx, (
                  start: now.subtract(const Duration(days: 30)),
                  end: now,
                  label: 'Último mes',
                ));
              }),
              tile(Icons.date_range_rounded, 'Rango personalizado',
                  'Elegir fecha desde / hasta', () async {
                final range = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (range != null && ctx.mounted) {
                  final f = DateFormat('dd/MM/yyyy');
                  Navigator.pop(ctx, (
                    start: DateTime(range.start.year, range.start.month,
                        range.start.day),
                    end: DateTime(range.end.year, range.end.month, range.end.day,
                        23, 59, 59),
                    label: '${f.format(range.start)} - ${f.format(range.end)}',
                  ));
                }
              }),
              tile(Icons.all_inclusive_rounded, 'Todo el historial',
                  'Sin límite de fechas', () {
                Navigator.pop(ctx, (start: null, end: null, label: 'Todas las fechas'));
              }),
            ],
          ),
        );
      },
    );
  }

  List<MovementModel> _filterByPeriod(
      List<MovementModel> movements, DateTime? start, DateTime? end) {
    if (start == null && end == null) return movements;
    return movements.where((m) {
      final d = DateTime.tryParse(m.date);
      if (d == null) return false;
      if (start != null && d.isBefore(start)) return false;
      if (end != null && d.isAfter(end)) return false;
      return true;
    }).toList();
  }

  // ---------- Handlers de cada reporte ----------
  void _inventoryReport() {
    final products = context.read<ProductsProvider>().products;
    final categories = context.read<CategoriesProvider>().categories;
    DownloadOptionsSheet.show(
      context,
      title: 'Reporte de Inventario',
      subtitle: 'Estado actual del stock',
      options: [
        DownloadOption(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exportar PDF',
          subtitle: 'Documento para imprimir',
          color: const Color(0xFFDC2626),
          onTap: () => PdfService.generateInventoryReport(products, categories),
        ),
        DownloadOption(
          icon: Icons.table_chart_rounded,
          title: 'Exportar Excel',
          subtitle: 'Archivo .xlsx',
          color: const Color(0xFF16A34A),
          onTap: () => ExcelService.exportInventory(products, categories),
        ),
      ],
    );
  }

  Future<void> _movementsReport() async {
    final period = await _choosePeriod();
    if (period == null || !mounted) return;

    final all = context.read<MovementsProvider>().movements;
    final products = context.read<ProductsProvider>().products;
    final warehouses = context.read<WarehousesProvider>().warehouses;
    final projects = context.read<ProjectsProvider>().projects;
    final users = context.read<UsersProvider>().users;
    final filtered = _filterByPeriod(all, period.start, period.end);

    if (filtered.isEmpty) {
      CustomSnackBar.showWarning(context, 'No hay movimientos en ese periodo');
      return;
    }

    DownloadOptionsSheet.show(
      context,
      title: 'Reporte de Movimientos',
      subtitle: period.label,
      options: [
        DownloadOption(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exportar PDF',
          subtitle: 'Documento para imprimir',
          color: const Color(0xFFDC2626),
          onTap: () => PdfService.generateAndPrintMovementsReport(
              filtered, products),
        ),
        DownloadOption(
          icon: Icons.table_chart_rounded,
          title: 'Exportar Excel',
          subtitle: 'Archivo .xlsx',
          color: const Color(0xFF16A34A),
          onTap: () => ExcelService.exportMovements(
              filtered, products, warehouses, projects, users),
        ),
      ],
    );
  }

  Future<void> _auditReport() async {
    final period = await _choosePeriod();
    if (period == null || !mounted) return;

    final all = context.read<MovementsProvider>().movements;
    final products = context.read<ProductsProvider>().products;
    final warehouses = context.read<WarehousesProvider>().warehouses;
    final projects = context.read<ProjectsProvider>().projects;
    final users = context.read<UsersProvider>().users;
    final filtered = _filterByPeriod(all, period.start, period.end);

    if (filtered.isEmpty) {
      CustomSnackBar.showWarning(context, 'No hay movimientos en ese periodo');
      return;
    }

    await PdfService.generateAuditReport(
      filtered,
      products,
      warehouses,
      projects,
      users,
      periodLabel: period.label,
    );
  }

  Future<void> _projectReport() async {
    final projects = context.read<ProjectsProvider>().projects;
    if (projects.isEmpty) {
      CustomSnackBar.showWarning(context, 'No hay proyectos registrados');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<ProjectModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Elige el proyecto',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(ctx).colorScheme.onSurface)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: projects
                        .map((p) => ListTile(
                              leading: const Icon(Icons.business_center_outlined),
                              title: Text(p.name),
                              onTap: () => Navigator.pop(ctx, p),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final movements = context.read<MovementsProvider>().movements;
    final products = context.read<ProductsProvider>().products;
    await PdfService.generateProjectReport(selected, movements, products);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Reportes'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _reportCard(
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF2563EB),
            title: 'Reporte de Inventario',
            subtitle: 'Estado actual del stock (PDF / Excel)',
            isDark: isDark,
            onTap: _inventoryReport,
          ),
          _reportCard(
            icon: Icons.compare_arrows_rounded,
            color: const Color(0xFF16A34A),
            title: 'Reporte de Movimientos',
            subtitle: 'Entradas y salidas por periodo (PDF / Excel)',
            isDark: isDark,
            onTap: _movementsReport,
          ),
          _reportCard(
            icon: Icons.business_center_outlined,
            color: const Color(0xFF8B5CF6),
            title: 'Reporte por Proyecto',
            subtitle: 'Consumo de materiales y costos (PDF)',
            isDark: isDark,
            onTap: _projectReport,
          ),
          _reportCard(
            icon: Icons.verified_user_outlined,
            color: const Color(0xFFDC2626),
            title: 'Reporte de Auditoría',
            subtitle: 'Movimientos inalterables, solo lectura (PDF)',
            isDark: isDark,
            onTap: _auditReport,
          ),
        ],
      ),
    );
  }

  Widget _reportCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.download_rounded, color: color, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
