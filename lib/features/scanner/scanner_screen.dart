import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_shadows.dart';
import '../../data/providers/products_provider.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/models/product_model.dart';
import '../inventory/widgets/movement_form_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;
  bool _isBarcodeMode = false;
  late AnimationController _animationController;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _loadRotationPreference();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadRotationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _rotationQuarterTurns = prefs.getInt('scanner_rotation_turns') ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading rotation preference: $e');
    }
  }

  Future<void> _saveRotationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('scanner_rotation_turns', _rotationQuarterTurns);
    } catch (e) {
      debugPrint('Error saving rotation preference: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        final String code = barcode.rawValue!;

        // Retroalimentación física (Vibración)
        HapticFeedback.heavyImpact();

        // Detener el escáner mientras se muestra la información
        _scannerController.stop();

        // Primero mostrar la tarjeta con la información del producto (HU07)
        await _showProductInfo(code);

        // Reiniciar el escáner cuando se cierre todo
        if (mounted) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
        break;
      }
    }
  }

  Future<void> _showProductInfo(String code) async {
    final productsProvider = context.read<ProductsProvider>();
    final categoriesProvider = context.read<CategoriesProvider>();

    if (productsProvider.products.isEmpty) {
      await productsProvider.fetchProducts();
    }
    if (categoriesProvider.categories.isEmpty) {
      await categoriesProvider.fetchCategories();
    }
    if (!mounted) return;

    ProductModel? product;
    for (final p in productsProvider.products) {
      // Un producto puede identificarse por el código de fábrica, por el QR
      // interno o por el número de serie de una unidad individual.
      if (p.code == code || p.internalQr == code || p.serialNumber == code) {
        product = p;
        break;
      }
    }

    final categoryName = product?.categoryId == null
        ? 'Sin categoría'
        : categoriesProvider.categories
                .where((c) => c.id == product!.categoryId)
                .map((c) => c.name)
                .firstOrNull ??
            'Sin categoría';

    // La tarjeta devuelve true si el usuario quiere registrar un movimiento.
    final register = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScannedProductSheet(
        code: code,
        product: product,
        categoryName: categoryName,
      ),
    );

    if (register == true && mounted) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MovementFormDialog(prefilledCode: code),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scanWindowWidth = _isBarcodeMode ? screenWidth * 0.85 : screenWidth * 0.7;
    final scanWindowHeight = _isBarcodeMode ? 140.0 : screenWidth * 0.7;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    final activeTextColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Escanear Código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
              });
              _saveRotationPreference();
            },
            tooltip: 'Rotar cámara',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RotatedBox(
            quarterTurns: _rotationQuarterTurns,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          
          // Capa semi-transparente alrededor del área de escaneo
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: scanWindowHeight,
                    width: scanWindowWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bordes del escáner y animación láser
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: scanWindowHeight,
              width: scanWindowWidth,
              child: Stack(
                children: [
                  // Esquinas decorativas
                  _buildCorner(Alignment.topLeft, activeColor),
                  _buildCorner(Alignment.topRight, activeColor),
                  _buildCorner(Alignment.bottomLeft, activeColor),
                  _buildCorner(Alignment.bottomRight, activeColor),
                  
                  // Animación de barrido (Láser rojo)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (scanWindowHeight - 4),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: AppShadows.tinted(Colors.redAccent, alpha: 0.35),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Selector de modo interactivo en la parte superior
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isBarcodeMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isBarcodeMode ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2, color: !_isBarcodeMode ? activeTextColor : Colors.white54, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Modo QR',
                              style: TextStyle(
                                color: !_isBarcodeMode ? activeTextColor : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isBarcodeMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isBarcodeMode ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.barcode_reader, color: _isBarcodeMode ? activeTextColor : Colors.white54, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Modo Barras',
                              style: TextStyle(
                                color: _isBarcodeMode ? activeTextColor : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 40),
                const SizedBox(height: 16),
                Text(
                  _isBarcodeMode ? 'Alinea el código de barras' : 'Alinea el código QR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'El escaneo e identificación son automáticos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight) 
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) 
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) 
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
                ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que muestra la información del producto escaneado (HU07)
/// con la opción de registrar un movimiento.
class _ScannedProductSheet extends StatelessWidget {
  final String code;
  final ProductModel? product;
  final String categoryName;

  const _ScannedProductSheet({
    required this.code,
    required this.product,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    final found = product != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
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
          if (!found) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search_off_rounded,
                      color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto no encontrado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Código: $code',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cerrar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: accent)),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    product!.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow(context, isDark, Icons.qr_code_2, 'Código', product!.code),
            if (product!.internalQr?.isNotEmpty == true)
              _infoRow(context, isDark, Icons.qr_code, 'QR interno',
                  product!.internalQr!),
            _infoRow(context, isDark, Icons.category_outlined, 'Categoría',
                categoryName),
            if (product!.subtype?.isNotEmpty == true)
              _infoRow(context, isDark, Icons.category, 'Subtipo',
                  product!.subtype!),
            if (product!.brand?.isNotEmpty == true)
              _infoRow(context, isDark, Icons.business_outlined, 'Marca',
                  product!.brand!),
            if (product!.model?.isNotEmpty == true)
              _infoRow(context, isDark, Icons.precision_manufacturing_outlined,
                  'Modelo', product!.model!),
            ...product!.attributes.entries.map(
              (entry) => _infoRow(
                context,
                isDark,
                Icons.tune_outlined,
                entry.key,
                entry.value.toString(),
              ),
            ),
            _infoRow(context, isDark, Icons.inventory_2_outlined, 'Stock actual',
                '${product!.stock} ${product!.unit?.isNotEmpty == true ? product!.unit : 'und'}'),
            _infoRow(
              context,
              isDark,
              Icons.payments_outlined,
              'Precio',
              '${product!.currency == 'USD' ? '\$' : 'S/.'} ${product!.price.toStringAsFixed(2)}',
            ),
            if (product!.serialNumber?.isNotEmpty == true)
              _infoRow(context, isDark, Icons.tag, 'N° de serie',
                  product!.serialNumber!),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cerrar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accent)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor:
                          isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 20),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Registrar movimiento',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, bool isDark, IconData icon, String label,
      String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
