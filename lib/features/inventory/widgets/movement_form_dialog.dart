import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/movement_model.dart';
import '../../../data/providers/movements_provider.dart';
import '../../../data/providers/products_provider.dart';
import '../../../data/providers/warehouses_provider.dart';
import '../../../data/providers/projects_provider.dart';
import '../../auth/auth_provider.dart';

class MovementFormDialog extends StatefulWidget {
  final String? prefilledCode;
  
  const MovementFormDialog({super.key, this.prefilledCode});

  @override
  State<MovementFormDialog> createState() => _MovementFormDialogState();
}

class _MovementFormDialogState extends State<MovementFormDialog> {
  String? type; 
  int? selectedProductId;
  int? selectedWarehouseId;
  int? selectedProjectId;
  
  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final productsProvider = context.read<ProductsProvider>();
      final warehousesProvider = context.read<WarehousesProvider>();
      final projectsProvider = context.read<ProjectsProvider>();

      await productsProvider.fetchProducts();
      await warehousesProvider.fetchWarehouses();
      await projectsProvider.fetchProjects();

      if (mounted) {
        final products = productsProvider.products.where((p) => p.isActive).toList();
        
        if (products.isNotEmpty) {
          if (widget.prefilledCode != null) {
            try {
              selectedProductId = products.firstWhere((p) => p.code == widget.prefilledCode).id;
            } catch (_) {
              selectedProductId = null;
            }
          } else {
            selectedProductId = null;
          }
        }
        
        selectedWarehouseId = null;
        selectedProjectId = null;

        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {

    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final products = context.watch<ProductsProvider>().products.where((p) => p.isActive).toList();
    final warehouses = context.watch<WarehousesProvider>().warehouses.where((w) => w.isActive).toList();
    final projects = context.watch<ProjectsProvider>().projects.where((p) => p.status == 'active').toList();
    final user = context.watch<AuthProvider>().currentUser;

    if (products.isEmpty || warehouses.isEmpty || user == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: Text('Debe registrar productos y almacenes activos primero.')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle drag indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registrar Movimiento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdownField<String>(
                      label: 'Tipo de Movimiento',
                      icon: Icons.swap_vert,
                      isDark: isDark,
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'OUT', child: Text('SALIDA (Retirar Stock)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                        DropdownMenuItem(value: 'IN', child: Text('ENTRADA (Añadir Stock)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                      onChanged: (val) => setState(() => type = val),
                      hint: Text(
                        'Seleccione tipo de movimiento',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<int>(
                      label: 'Producto',
                      icon: Icons.inventory_2_outlined,
                      isDark: isDark,
                      value: selectedProductId,
                      items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => selectedProductId = val),
                      hint: Text(
                        'Seleccione un producto',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<int>(
                      label: 'Almacén',
                      icon: Icons.storefront_outlined,
                      isDark: isDark,
                      value: selectedWarehouseId,
                      items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => selectedWarehouseId = val),
                      hint: Text(
                        'Seleccione un almacén',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (type == 'OUT' && projects.isNotEmpty) ...[
                      _buildDropdownField<int>(
                        label: 'Proyecto (Obligatorio)',
                        icon: Icons.assignment_outlined,
                        isDark: isDark,
                        value: selectedProjectId,
                        items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => selectedProjectId = val),
                        validator: (val) => val == null ? 'Seleccione un proyecto' : null,
                        hint: Text(
                          'Seleccione un proyecto',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildFormField(
                      controller: quantityController,
                      label: 'Cantidad',
                      hint: 'Ej. 10',
                      icon: Icons.tag,
                      isDark: isDark,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: notesController,
                      label: 'Notas / Referencia (Opcional)',
                      hint: 'Ej. Orden de compra 123',
                      icon: Icons.notes_outlined,
                      isDark: isDark,
                      maxLines: 2,
                      isRequired: false,
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
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final mov = MovementModel(
                                  productId: selectedProductId!,
                                  warehouseId: selectedWarehouseId!,
                                  projectId: type == 'OUT' ? selectedProjectId : null,
                                  userId: user.id!,
                                  type: type!,
                                  quantity: int.parse(quantityController.text),
                                  date: DateTime.now().toIso8601String(),
                                  notes: notesController.text.trim(),
                                );
                                
                                final success = await context.read<MovementsProvider>().registerMovement(mov);
                                
                                if (context.mounted) {
                                  if (success) {
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Movimiento registrado con éxito.'), backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Stock insuficiente para realizar esta salida.'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: type == 'IN' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
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
    bool isNumber = false,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      validator: (val) {
        if (isRequired && (val == null || val.isEmpty)) return 'Requerido';
        if (isNumber && val != null && val.isNotEmpty) {
          if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Cantidad inválida';
        }
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

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required bool isDark,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    Widget? hint,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      validator: validator ?? (val) {
        if (val == null) return 'Requerido';
        return null;
      },
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.black54,
          fontSize: 14,
        ),
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
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
    );
  }
}
