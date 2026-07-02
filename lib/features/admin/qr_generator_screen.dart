import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../data/providers/products_provider.dart';
import '../../data/models/product_model.dart';
import '../../core/services/pdf_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final List<ProductModel> _selectedProducts = [];
  String _searchQuery = '';
  bool _isBarcode = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts();
    });
  }

  void _toggleProductSelection(ProductModel product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  void _selectAll(List<ProductModel> allProducts) {
    setState(() {
      if (_selectedProducts.length == allProducts.length) {
        _selectedProducts.clear();
      } else {
        _selectedProducts.clear();
        _selectedProducts.addAll(allProducts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Códigos QR'),
        actions: [
          Consumer<ProductsProvider>(
            builder: (context, provider, child) {
              return TextButton.icon(
                onPressed: provider.products.isEmpty ? null : () => _selectAll(provider.products),
                icon: Icon(
                  _selectedProducts.length == provider.products.length ? Icons.deselect : Icons.select_all,
                  color: Colors.white
                ),
                label: Text(
                  _selectedProducts.length == provider.products.length ? 'Deseleccionar' : 'Todos',
                  style: const TextStyle(color: Colors.white)
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _selectedProducts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await PdfService.generateLabelsPdf(_selectedProducts, isBarcode: _isBarcode);
              },
              icon: const Icon(Icons.print),
              label: Text('Imprimir PDF (${_selectedProducts.length})'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return const Center(child: Text('No hay productos registrados.'));
          }

          final filteredProducts = provider.products.where((p) {
            return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                   p.code.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text('Barras', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _isBarcode,
                          onChanged: (val) => setState(() => _isBarcode = val),
                          activeThumbColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              if (filteredProducts.isEmpty)
                const Expanded(child: Center(child: Text('No se encontraron resultados.')))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final prod = filteredProducts[index];
                      final isSelected = _selectedProducts.contains(prod);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                        ),
                        child: ListTile(
                          onTap: () => _toggleProductSelection(prod),
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: _isBarcode
                                ? BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: prod.code,
                                    drawText: false,
                                  )
                                : QrImageView(
                                    data: prod.code,
                                    version: QrVersions.auto,
                                  ),
                          ),
                          title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('SKU: ${prod.code}'),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (val) => _toggleProductSelection(prod),
                            activeColor: Theme.of(context).primaryColor,
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
