import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_shadows.dart';
import '../inventory/widgets/movement_form_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
        
        // Detener el escáner mientras se muestra el formulario
        _scannerController.stop();
        
        // Mostrar el formulario directamente sobre la cámara
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => MovementFormDialog(prefilledCode: code),
        );
        
        // Reiniciar el escáner cuando se cierre el diálogo
        if (mounted) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
        break;
      }
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
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
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
