import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/products_provider.dart';
import '../../data/models/product_model.dart';
import 'package:go_router/go_router.dart';

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

  void _showProductForm([ProductModel? product]) {
    final isEditing = product != null;
    final codeController = TextEditingController(text: product?.code ?? '');
    final serialNumberController = TextEditingController(text: product?.serialNumber ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '0');
    final minStockController = TextEditingController(text: product?.minStock.toString() ?? '5');
    final unitController = TextEditingController(text: product?.unit ?? 'Unidad');
    final priceController = TextEditingController(text: product?.price.toString() ?? '0.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Código / SKU'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: serialNumberController,
                    decoration: const InputDecoration(labelText: 'Número de Serie (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(labelText: 'Stock Inicial'),
                          keyboardType: TextInputType.number,
                          enabled: !isEditing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: minStockController,
                          decoration: const InputDecoration(labelText: 'Stock Mínimo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(labelText: 'Unidad (ej. Kg, Lt)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Precio Unit.'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
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
              child: const Text('Guardar'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear Código',
            onPressed: () {
              context.push('/scanner');
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrado
          var filteredList = provider.products.where((p) {
            final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                 p.code.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesStockFilter = _showOnlyLowStock ? p.stock <= p.minStock : true;
            return matchesQuery && matchesStockFilter;
          }).toList();

          return Column(
            children: [
              // Panel de Búsqueda
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1959AD)),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredList.length} productos',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            const Text('Stock Crítico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            Switch(
                              value: _showOnlyLowStock,
                              activeThumbColor: const Color(0xFFFCD34D), // color-accent-light
                              activeTrackColor: const Color(0xFFF5DE0B).withValues(alpha: 0.5),
                              onChanged: (val) {
                                setState(() {
                                  _showOnlyLowStock = val;
                                });
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de Resultados
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No se encontraron resultados', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final prod = filteredList[index];
                          final isLowStock = prod.stock <= prod.minStock;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isLowStock ? Colors.redAccent.shade200 : Colors.grey.shade200,
                                width: isLowStock ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showProductForm(prod),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.red.shade50 : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: isLowStock ? Colors.red : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prod.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text('SKU: ${prod.code}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                          if (prod.serialNumber != null) 
                                            Text('S/N: ${prod.serialNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                          Text('\$${prod.price.toStringAsFixed(2)} / ${prod.unit}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${prod.stock}',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: isLowStock ? Colors.red : Colors.green.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Stock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
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
