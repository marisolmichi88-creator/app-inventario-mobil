import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/models/product_model.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/custom_snackbar.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts();
    });
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
          title: const Text('¿Estás seguro?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('¿Desea eliminar el producto "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx); // Cerrar diálogo
                Navigator.pop(context); // Cerrar BottomSheet
                
                final deleted = await context.read<ProductsProvider>().deleteProduct(product.id!);
                
                if (context.mounted) {
                  if (deleted) {
                    CustomSnackBar.showSuccess(context, 'Producto eliminado');
                  } else {
                    CustomSnackBar.showWarning(context, 'Producto desactivado');
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showProductForm([ProductModel? product]) {
    final isEditing = product != null;
    final codeController = TextEditingController(text: product?.code ?? '');
    final serialNumberController = TextEditingController(text: product?.serialNumber ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final minStockController = TextEditingController(text: product?.minStock.toString() ?? '5');
    final unitController = TextEditingController(text: product?.unit ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentUser = context.read<AuthProvider>().currentUser;
        final isAdmin = currentUser?.role == 'admin';
        String selectedCurrency = product?.currency ?? 'PEN';
        
        return StatefulBuilder(
          builder: (context, setState) {
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
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteProduct(context, product),
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          controller: stockController,
                          label: isEditing ? 'Stock Actual' : 'Stock Inicial',
                          hint: '0',
                          icon: Icons.inventory_2_outlined,
                          isNumber: true,
                          isDark: isDark,
                          enabled: isAdmin,
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
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          decoration: InputDecoration(
                            labelText: 'Moneda',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PEN', child: Text('Soles')),
                            DropdownMenuItem(value: 'USD', child: Text('Dólares')),
                          ],
                          onChanged: isAdmin ? (val) {
                            if (val != null) {
                              setState(() => selectedCurrency = val);
                            }
                          } : null,
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
                  const SizedBox(height: 16),
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
                            isAdmin ? 'Cancelar' : 'Cerrar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                            ),
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final newProduct = ProductModel(
                                  id: product?.id,
                                  code: codeController.text.trim(),
                                  serialNumber: serialNumberController.text.trim().isEmpty ? null : serialNumberController.text.trim(),
                                  name: nameController.text.trim(),
                                  stock: int.tryParse(stockController.text) ?? 0,
                                  minStock: int.tryParse(minStockController.text) ?? 0,
                                  unit: unitController.text.trim(),
                                  price: double.tryParse(priceController.text) ?? 0.0,
                                  currency: selectedCurrency,
                                  isActive: product?.isActive ?? true,
                                );
                                
                                if (isEditing) {
                                  context.read<ProductsProvider>().updateProduct(newProduct);
                                } else {
                                  context.read<ProductsProvider>().addProduct(newProduct);
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
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          'Catálogo de Productos', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 22, letterSpacing: -0.5)
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded, color: isDark ? Colors.white : const Color(0xFF2563EB), size: 20),
              tooltip: 'Escanear Código',
              onPressed: () {
                context.push('/scanner');
              },
            ),
          )
        ],
      ),
      floatingActionButton: context.watch<AuthProvider>().currentUser?.role == 'admin' 
        ? FloatingActionButton.extended(
            onPressed: () => _showProductForm(),
            backgroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 1,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        : null,
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var filteredList = provider.products.where((p) {
            final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                 p.code.toLowerCase().contains(_searchQuery.toLowerCase());
            return _showOnlyLowStock ? (matchesQuery && p.stock <= p.minStock) : matchesQuery;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.card(isDark: isDark),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              
              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E40AF).withValues(alpha: 0.5) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: isDark ? Colors.blue.shade300 : const Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${filteredList.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text('Productos', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                'Stock Crítico', 
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _showOnlyLowStock,
                                onChanged: (val) => setState(() => _showOnlyLowStock = val),
                                activeThumbColor: Colors.white,
                                activeTrackColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                              ),
                            ),
                          ],
                        ),
                      )
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
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No se encontraron productos', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final prod = filteredList[index];
                        final isLowStock = prod.stock <= prod.minStock;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.card(isDark: isDark),
                            border: isLowStock ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1) : null,
                          ),
                          child: InkWell(
                            onTap: () => _showProductForm(prod),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF60A5FA).withValues(alpha: 0.15) : const Color(0xFF1959AD).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.inventory_2_outlined, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name.toUpperCase(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.25),
                                        ),
                                        const SizedBox(height: 6),
                                        Text('SKU: ${prod.code}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${prod.currency == 'USD' ? '\$' : 'S/.'} ${prod.price.toStringAsFixed(2)} / ${prod.unit?.isNotEmpty == true ? prod.unit : 'UND'}',
                                          style: TextStyle(color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD), fontWeight: FontWeight.w900, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isLowStock 
                                              ? (isDark ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFFFEE2E2)) 
                                              : (isDark ? const Color(0xFF16A34A).withValues(alpha: 0.2) : const Color(0xFFDCFCE7)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${prod.stock}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: isLowStock 
                                                ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)) 
                                                : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Stock', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
