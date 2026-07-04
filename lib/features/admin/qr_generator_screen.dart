import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/admin_ui.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(
        context,
        'Generador de Etiquetas',
        actions: [
          Consumer<ProductsProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: provider.products.isEmpty ? null : () => _selectAll(provider.products),
                  icon: Icon(
                    _selectedProducts.length == provider.products.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                  ),
                  label: Text(
                    _selectedProducts.length == provider.products.length ? 'Deseleccionar' : 'Todos',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              icon: const Icon(Icons.print_rounded),
              label: Text('Imprimir PDF (${_selectedProducts.length})'),
              backgroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
              foregroundColor: Colors.white,
              elevation: 1,
            ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.qr_code_2_outlined,
              title: 'No hay productos registrados',
              subtitle: 'Agrega productos al catálogo para generar etiquetas.',
            );
          }

          final filteredProducts = provider.products.where((p) {
            return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.code.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(
                            hintText: 'Buscar producto...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.card(isDark: isDark),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Barras',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Switch.adaptive(
                            value: _isBarcode,
                            onChanged: (val) => setState(() => _isBarcode = val),
                            activeTrackColor: (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD))
                                .withValues(alpha: 0.5),
                            activeThumbColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (filteredProducts.isEmpty)
                const Expanded(
                  child: AdminEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Sin resultados',
                    subtitle: 'Prueba con otro nombre o código.',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final prod = filteredProducts[index];
                      final isSelected = _selectedProducts.contains(prod);
                      final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.card(isDark: isDark),
                          border: isSelected
                              ? Border.all(color: accent, width: 1.5)
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleProductSelection(prod),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.95)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'SKU: ${prod.code}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (val) => _toggleProductSelection(prod),
                                    activeColor: accent,
                                  ),
                                ],
                              ),
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
