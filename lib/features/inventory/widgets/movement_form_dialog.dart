import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/movement_model.dart';
import '../../../data/providers/movements_provider.dart';
import '../../../data/providers/products_provider.dart';
import '../../../data/providers/warehouses_provider.dart';
import '../../../data/providers/projects_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../core/widgets/custom_snackbar.dart';

class MovementFormDialog extends StatefulWidget {
  final String? prefilledCode;
  final String? prefilledProjectId;
  final String? prefilledType;
  final String? prefilledWarehouseId;

  const MovementFormDialog({
    super.key,
    this.prefilledCode,
    this.prefilledProjectId,
    this.prefilledType,
    this.prefilledWarehouseId,
  });

  @override
  State<MovementFormDialog> createState() => _MovementFormDialogState();
}

class _MovementFormDialogState extends State<MovementFormDialog> {
  String? type;
  String? selectedProductId;
  String? selectedWarehouseId;
  String? selectedProjectId;
  String? selectedUserId;
  String? stockObservation;

  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final destinationController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  /// Mientras se sube la foto y se guarda: evita registrar dos veces la
  /// misma salida por tocar Guardar de nuevo.
  bool _isSaving = false;

  /// Foto de lo que sale. En una salida es obligatoria: es la constancia de
  /// qué se llevó cada quien.
  Uint8List? _photo;
  String _photoExtension = 'jpg';
  String? _errorBanner;

  @override
  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(FormFieldState<Uint8List> field) async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        // Suficiente para reconocer el material y liviana para subirla con
        // datos móviles desde la obra.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
      );
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      final name = shot.name.toLowerCase();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoExtension = name.contains('.') ? name.split('.').last : 'jpg';
      });
      field.didChange(bytes);
    } on PlatformException catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context,
        e.code == 'camera_access_denied'
            ? 'La app no tiene permiso para usar la cámara. Actívalo en los '
                'ajustes del celular.'
            : 'No se pudo abrir la cámara: ${e.message ?? e.code}',
      );
    }
  }

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
        final products = productsProvider.products
            .where((p) => p.isActive)
            .toList();
        final warehouses = warehousesProvider.warehouses
            .where((w) => w.isActive)
            .toList();

        if (products.isNotEmpty) {
          if (widget.prefilledCode != null) {
            final foundProd = ProductsProvider.findByCode(
              products,
              widget.prefilledCode!,
            );
            selectedProductId = foundProd?.id;
            selectedWarehouseId = widget.prefilledWarehouseId ??
                foundProd?.warehouseId ??
                (warehouses.length == 1 ? warehouses.first.id : null);
          } else {
            selectedProductId = null;
            selectedWarehouseId = widget.prefilledWarehouseId ??
                (warehouses.length == 1 ? warehouses.first.id : null);
          }
        }

        selectedProjectId = widget.prefilledProjectId;
        type = widget.prefilledType;
        selectedUserId = context.read<AuthProvider>().currentUser?.id;

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

    final products = context
        .watch<ProductsProvider>()
        .products
        .where((p) => p.isActive)
        .toList();
    final warehouses = context
        .watch<WarehousesProvider>()
        .warehouses
        .where((w) => w.isActive)
        .toList();
    final projects = context
        .watch<ProjectsProvider>()
        .projects
        .where((p) => p.status == 'active')
        .toList();
    final user = context.watch<AuthProvider>().currentUser;

    if (products.isEmpty || warehouses.isEmpty || user == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Text('Debe registrar productos y almacenes activos primero.'),
        ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
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
                    if (_errorBanner != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorBanner!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildDropdownField<String>(
                      label: 'Tipo de Movimiento',
                      icon: Icons.swap_vert,
                      isDark: isDark,
                      value: type,
                      items: const [
                        DropdownMenuItem(
                          value: 'OUT',
                          child: Text(
                            'SALIDA (Retirar Stock)',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'IN',
                          child: Text(
                            'ENTRADA (Añadir Stock)',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
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
                    _buildDropdownField<String>(
                      label: 'Producto',
                      icon: Icons.inventory_2_outlined,
                      isDark: isDark,
                      value: selectedProductId,
                      items: products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedProductId = val;
                          final prod = products.where((p) => p.id == val).firstOrNull;
                          if (prod?.warehouseId != null && selectedWarehouseId == null) {
                            selectedWarehouseId = prod!.warehouseId;
                          }
                        });
                      },
                      hint: Text(
                        'Seleccione un producto',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<String>(
                      label: 'Almacén',
                      icon: Icons.storefront_outlined,
                      isDark: isDark,
                      value: selectedWarehouseId,
                      items: warehouses
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedWarehouseId = val),
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
                      _buildDropdownField<String>(
                        label: 'Proyecto (Obligatorio)',
                        icon: Icons.assignment_outlined,
                        isDark: isDark,
                        value: selectedProjectId,
                        items: projects
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedProjectId = val),
                        validator: (val) =>
                            val == null ? 'Seleccione un proyecto' : null,
                        hint: Text(
                          'Seleccione un proyecto',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (type == 'OUT') ...[
                      _buildFormField(
                        controller: destinationController,
                        label: 'Destino / lugar a dónde va',
                        hint: 'Ej. Obra Av. Grau, planta Chilca',
                        icon: Icons.place_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildPhotoField(isDark),
                      const SizedBox(height: 16),
                    ],
                    _buildFormField(
                      controller: quantityController,
                      label: 'Cantidad',
                      hint: 'Ej. 10',
                      icon: Icons.tag,
                      isDark: isDark,
                      isNumber: true,
                      autofocus: widget.prefilledCode != null,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () async {
                              if (formKey.currentState!.validate()) {
                                final isOut = type == 'OUT';
                                final mov = MovementModel(
                                  productId: selectedProductId!,
                                  warehouseId: selectedWarehouseId!,
                                  projectId: isOut ? selectedProjectId : null,
                                  userId: user.id!,
                                  type: type!,
                                  quantity: int.parse(quantityController.text),
                                  date: DateTime.now().toIso8601String(),
                                  notes: notesController.text.trim(),
                                  destination: isOut
                                      ? destinationController.text.trim()
                                      : null,
                                );

                                setState(() => _isSaving = true);
                                final error = await context
                                    .read<MovementsProvider>()
                                    .registerMovement(
                                      mov,
                                      photo: isOut ? _photo : null,
                                      photoExtension: _photoExtension,
                                    );

                                if (context.mounted) {
                                  setState(() {
                                    _isSaving = false;
                                    _errorBanner = error;
                                  });
                                  if (error == null) {
                                    Navigator.pop(context, true);
                                    CustomSnackBar.showSuccess(
                                      context,
                                      'Registro exitoso',
                                    );
                                  } else {
                                    CustomSnackBar.showError(context, error);
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: type == 'IN'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 20),
                            label: Text(
                              _isSaving ? 'Guardando…' : 'Guardar',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  /// Foto obligatoria de la salida. Es un FormField para que el formulario
  /// la valide junto con los demás campos al tocar Guardar.
  Widget _buildPhotoField(bool isDark) {
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);
    return FormField<Uint8List>(
      initialValue: _photo,
      validator: (val) =>
          val == null ? 'Toma una foto de lo que sale' : null,
      builder: (field) {
        final borderColor = field.hasError
            ? Theme.of(context).colorScheme.error
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_photo == null)
              InkWell(
                onTap: _isSaving ? null : () => _takePhoto(field),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.photo_camera_outlined, color: accent, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        'Tomar foto de lo que sale',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.memory(
                      _photo!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _isSaving ? null : () => _takePhoto(field),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tomar otra'),
                      ),
                    ),
                  ],
                ),
              ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
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
    bool isRequired = true,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      validator: (val) {
        if (isRequired && (val == null || val.isEmpty)) return 'Requerido';
        if (isNumber && val != null && val.isNotEmpty) {
          if (int.tryParse(val) == null || int.parse(val) <= 0) {
            return 'Cantidad inválida';
          }
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
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : Colors.black87,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
    Widget? hint,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      validator:
          validator ??
          (val) {
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
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : Colors.black87,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
    );
  }
}
