import 'package:flutter/material.dart';

Future<void> showAdminFormSheet({
  required BuildContext context,
  required String title,
  required GlobalKey<FormState> formKey,
  required List<Widget> Function(
    BuildContext context,
    bool isDark,
    void Function(VoidCallback fn) setSheetState,
  ) buildFields,
  required VoidCallback onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(sheetContext).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...buildFields(sheetContext, isDark, setSheetState),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    AdminFormActions(
                      isDark: isDark,
                      onCancel: () => Navigator.pop(sheetContext),
                      onSave: () {
                        if (formKey.currentState!.validate()) {
                          onSave();
                          Navigator.pop(sheetContext);
                        }
                      },
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

class AdminFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool isNumber;
  final bool isRequired;
  final bool enabled;
  final int maxLines;
  final bool obscureText;

  const AdminFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.isNumber = false,
    this.isRequired = true,
    this.enabled = true,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      validator: (val) {
        if (!isRequired) return null;
        if (val == null || val.trim().isEmpty) return 'Requerido';
        return null;
      },
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        isDark: isDark,
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}

class AdminFormDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const AdminFormDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator ?? (val) => val == null ? 'Requerido' : null,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: _inputDecoration(
        isDark: isDark,
        label: label,
        icon: icon,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
    );
  }
}

class AdminFormActions extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const AdminFormActions({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
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
    );
  }
}

InputDecoration _inputDecoration({
  required bool isDark,
  required String label,
  String? hint,
  required IconData icon,
}) {
  return InputDecoration(
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
  );
}
