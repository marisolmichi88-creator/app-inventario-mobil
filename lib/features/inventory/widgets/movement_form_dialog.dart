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
  String type = 'OUT'; // Default a SALIDA porque es la acción más común del trabajador
  int? selectedProductId;
  int? selectedWarehouseId;
  int? selectedProjectId;
  
  final quantityController = TextEditingController(text: '1');
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
      await context.read<ProductsProvider>().fetchProducts();
      await context.read<WarehousesProvider>().fetchWarehouses();
      await context.read<ProjectsProvider>().fetchProjects();

      if (mounted) {
        final products = context.read<ProductsProvider>().products.where((p) => p.isActive).toList();
        final warehouses = context.read<WarehousesProvider>().warehouses.where((w) => w.isActive).toList();
        final projects = context.read<ProjectsProvider>().projects.where((p) => p.status == 'active').toList();
        
        if (products.isNotEmpty) {
          if (widget.prefilledCode != null) {
            try {
              selectedProductId = products.firstWhere((p) => p.code == widget.prefilledCode).id;
            } catch (_) {
              selectedProductId = products.first.id;
            }
          } else {
            selectedProductId = products.first.id;
          }
        }
        
        if (warehouses.isNotEmpty) {
          selectedWarehouseId = warehouses.first.id;
        }
        
        if (projects.isNotEmpty) {
          selectedProjectId = projects.first.id;
        }

        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final products = context.watch<ProductsProvider>().products.where((p) => p.isActive).toList();
    final warehouses = context.watch<WarehousesProvider>().warehouses.where((w) => w.isActive).toList();
    final projects = context.watch<ProjectsProvider>().projects.where((p) => p.status == 'active').toList();
    final user = context.watch<AuthProvider>().currentUser;

    if (products.isEmpty || warehouses.isEmpty || user == null) {
      return const AlertDialog(
        content: Text('Debe registrar productos y almacenes activos primero.'),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Registrar Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de Movimiento'),
                items: const [
                  DropdownMenuItem(value: 'OUT', child: Text('SALIDA (Retirar Stock)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 'IN', child: Text('ENTRADA (Añadir Stock)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedProductId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Producto'),
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => selectedProductId = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedWarehouseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Almacén'),
                items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => selectedWarehouseId = val),
              ),
              const SizedBox(height: 16),
              if (type == 'OUT' && projects.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: selectedProjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Asignar a Proyecto (Obligatorio)'),
                  items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => selectedProjectId = val),
                  validator: (val) => val == null ? 'Debe seleccionar un proyecto para la salida' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Requerido';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Cantidad inválida';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notas / Referencia (Opcional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: type == 'IN' ? Colors.green : Colors.red),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final mov = MovementModel(
                productId: selectedProductId!,
                warehouseId: selectedWarehouseId!,
                projectId: type == 'OUT' ? selectedProjectId : null,
                userId: user.id!,
                type: type,
                quantity: int.parse(quantityController.text),
                date: DateTime.now().toIso8601String(),
                notes: notesController.text.trim(),
              );
              
              final success = await context.read<MovementsProvider>().registerMovement(mov);
              
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context, true); // Devuelve true si fue exitoso
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
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
