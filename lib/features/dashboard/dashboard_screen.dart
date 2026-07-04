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
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/theme_toggle_tile.dart';
import '../../core/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import '../../data/models/movement_model.dart';

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

  Widget _buildStockAlertItem(BuildContext context, ProductModel prod, ProductsProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.red.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Código: ${prod.code} | Stock: ${prod.stock} (Mín: ${prod.minStock})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () {
              provider.dismissAlert(prod.id!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovementAlertItem(BuildContext context, MovementModel mov, ProductModel prod, MovementsProvider provider, bool isDark) {
    final isEntry = mov.type == 'IN';
    final typeColor = isEntry ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    
    DateTime parsedDate = DateTime.tryParse(mov.date) ?? DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy • hh:mm a').format(parsedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : (isEntry ? Colors.green.shade50 : Colors.red.shade50).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? typeColor.withValues(alpha: 0.2) 
              : (isEntry ? Colors.green.shade100 : Colors.red.shade100),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntry ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isEntry ? 'Entrada' : 'Salida'}: ${prod.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cantidad: ${mov.quantity} | $formattedDate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () {
              provider.dismissMovementNotification(mov.id!);
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer2<ProductsProvider, MovementsProvider>(
          builder: (context, productsProvider, movementsProvider, child) {
            final dismissedIds = productsProvider.dismissedAlertProductIds;
            final activeCritical = productsProvider.products
                .where((p) => p.stock <= p.minStock && !dismissedIds.contains(p.id))
                .toList();

            final dismissedMovementIds = movementsProvider.dismissedMovementNotificationIds;
            final activeMovements = movementsProvider.movements
                .where((m) => !dismissedMovementIds.contains(m.id))
                .take(10)
                .toList();

            final totalActiveNotifications = activeCritical.length + activeMovements.length;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (totalActiveNotifications > 0)
                        TextButton.icon(
                          onPressed: () {
                            if (activeCritical.isNotEmpty) {
                              productsProvider.dismissAllAlerts(
                                activeCritical.map((p) => p.id!).toList(),
                              );
                            }
                            if (activeMovements.isNotEmpty) {
                              movementsProvider.dismissAllMovementNotifications(
                                activeMovements.map((m) => m.id!).toList(),
                              );
                            }
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.redAccent),
                          label: const Text('Limpiar todo', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (totalActiveNotifications == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 48,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes notificaciones pendientes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No hay alertas de stock ni movimientos recientes.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activeMovements.isNotEmpty) ...[
                              Text(
                                'Movimientos recientes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activeMovements.length,
                                itemBuilder: (context, index) {
                                  final mov = activeMovements[index];
                                  final prod = productsProvider.products.firstWhere(
                                    (p) => p.id == mov.productId,
                                    orElse: () => ProductModel(id: -1, name: 'Producto Desconocido', code: 'N/A'),
                                  );
                                  return _buildMovementAlertItem(context, mov, prod, movementsProvider, isDark);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (activeCritical.isNotEmpty) ...[
                              Text(
                                'Alertas de stock crítico',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activeCritical.length,
                                itemBuilder: (context, index) {
                                  final prod = activeCritical[index];
                                  return _buildStockAlertItem(context, prod, productsProvider, isDark);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
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

  void _showProfileBottomSheet(BuildContext context, dynamic user) {
    if (user == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      if (!isEditing) ...[
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                          child: Icon(Icons.person, size: 40, color: actionColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (user.role == 'admin' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role == 'admin' ? 'Administrador' : 'Operador',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: user.role == 'admin' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setModalState(() {
                                isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionColor,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Editar Perfil',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProfileFormField(
                          controller: nameController,
                          label: 'Nombre completo',
                          hint: 'Nombre y Apellido',
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileFormField(
                          controller: emailController,
                          label: 'Correo electrónico',
                          hint: 'correo@gmail.com',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            if (!val.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    isEditing = false;
                                    nameController.text = user.name;
                                    emailController.text = user.email;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: actionColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    await context.read<AuthProvider>().updateProfile(
                                      nameController.text.trim(),
                                      emailController.text.trim().toLowerCase(),
                                    );
                                    if (context.mounted) {
                                      CustomSnackBar.showSuccess(context, 'Perfil actualizado');
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: actionColor,
                                  foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    final activeStockAlertsCount = products
        .where((p) => p.stock <= p.minStock && !productsProvider.dismissedAlertProductIds.contains(p.id))
        .length;
    final activeMovementAlertsCount = movementsProvider.movements
        .where((m) => !movementsProvider.dismissedMovementNotificationIds.contains(m.id))
        .take(10)
        .length;
    final activeAlertsCount = activeStockAlertsCount + activeMovementAlertsCount;
    final normalStockProducts = totalProducts - lowStockProducts;
    final totalValuePEN = products
        .where((p) => p.currency == 'PEN')
        .fold<double>(0, (sum, item) => sum + (item.price * item.stock));
    final totalValueUSD = products
        .where((p) => p.currency == 'USD')
        .fold<double>(0, (sum, item) => sum + (item.price * item.stock));
    final totalCategories = categoriesProvider.categories.length;
    final recentMovements = movementsProvider.movements.take(2).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  _showNotificationsBottomSheet(context);
                },
              ),
              if (activeAlertsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$activeAlertsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => _showProfileBottomSheet(context, user),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                child: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.grey),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(height: 1, color: dividerColor),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.qr_code_2_outlined,
                      title: 'Generador de Etiquetas (QR)',
                      onTap: () => context.push('/qr-generator'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(height: 1, color: dividerColor),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1, color: dividerColor),
                  ),
                  ThemeToggleTile(
                    isDarkMode: themeProvider.isDarkMode,
                    onChanged: themeProvider.toggleTheme,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1, color: dividerColor),
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
                _buildMainValueCard(context, totalValuePEN, totalValueUSD),
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
                      child: Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: actionColor,
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
                      'Últimos Movimientos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/movements'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todos',
                          style: TextStyle(
                            color: actionColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (movementsProvider.movements.length > 2) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: actionColor,
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

  Widget _buildMainValueCard(BuildContext context, double totalValuePEN, double totalValueUSD) {
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
        boxShadow: AppShadows.tinted(const Color(0xFF3B82F6), alpha: 0.12),
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
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 24,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Soles (PEN)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'S/. ${totalValuePEN.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dólares (USD)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '\$ ${totalValueUSD.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
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
        boxShadow: AppShadows.card(isDark: isDark),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card(isDark: isDark)
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      startDegreeOffset: -90,
                      sections: total == 0
                          ? [
                              PieChartSectionData(
                                value: 1,
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                title: '',
                                radius: 18,
                              ),
                            ]
                          : [
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
                        Text(
                          '$total',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildChartLegend('Crítico', critical, criticalPct, const Color(0xFFEF4444), Theme.of(context).colorScheme.onSurface, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChartLegend('Normal', normal, normalPct, const Color(0xFF10B981), Theme.of(context).colorScheme.onSurface, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, int count, double pct, Color color, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count prod.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMovementsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    final textColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              color: actionColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos recientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra entradas o salidas de productos para verlas aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/movements?showForm=true'),
            style: ElevatedButton.styleFrom(
               backgroundColor: actionColor,
               foregroundColor: textColor,
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
               'Nuevo Movimiento',
               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
    final color = textColor ?? Theme.of(context).colorScheme.onSurface;
    final iColor = iconColor ?? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: showTrailing ? Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 20) : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
