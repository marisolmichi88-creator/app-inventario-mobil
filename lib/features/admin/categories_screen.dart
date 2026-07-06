import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().fetchCategories();
    });
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: (val) {
        if (!enabled) return null;
        if (maxLines == 1 && (val == null || val.isEmpty)) return 'Requerido';
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

  void _confirmDeleteCategory(BuildContext sheetContext, CategoryModel category) {
    showDialog(
      context: sheetContext,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text('¿Estás seguro?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('¿Desea eliminar la categoría "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx); // Cerrar diálogo
                Navigator.pop(sheetContext); // Cerrar formulario

                try {
                  final deleted = await context
                      .read<CategoriesProvider>()
                      .deleteCategory(category.id!);
                  if (!mounted) return;
                  if (deleted) {
                    CustomSnackBar.showSuccess(context, 'Categoría eliminada');
                  } else {
                    CustomSnackBar.showWarning(
                        context, 'No se puede eliminar: tiene productos asociados');
                  }
                } catch (_) {
                  if (mounted) {
                    CustomSnackBar.showError(context, 'Error al eliminar');
                  }
                }
              },
              child: const Text('Eliminar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryForm([CategoryModel? category]) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
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
                        isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              tooltip: 'Eliminar categoría',
                              onPressed: () =>
                                  _confirmDeleteCategory(context, category),
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
                    controller: nameController,
                    label: 'Nombre de la Categoría',
                    hint: 'Ej. Herramientas Eléctricas',
                    icon: Icons.local_offer_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: descController,
                    label: 'Descripción (Opcional)',
                    hint: 'Ej. Taladros, pulidoras y sierras',
                    icon: Icons.description_outlined,
                    isDark: isDark,
                    maxLines: 2,
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
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newCategory = CategoryModel(
                                id: category?.id,
                                name: nameController.text.trim(),
                                description: descController.text.trim(),
                                isActive: category?.isActive ?? true,
                              );
                              
                              if (isEditing) {
                                context.read<CategoriesProvider>().updateCategory(newCategory);
                              } else {
                                context.read<CategoriesProvider>().addCategory(newCategory);
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
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Gestión de Categorías'),
      floatingActionButton: adminFab(
        context: context,
        onPressed: () => _showCategoryForm(),
        label: 'Nueva Categoría',
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.categories.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No hay categorías registradas',
              subtitle: 'Crea categorías para clasificar tus productos.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final cat = provider.categories[index];

              return AdminListCard(
                icon: Icons.local_offer_outlined,
                iconColor: cat.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                iconBackground: cat.isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                title: cat.name,
                subtitle: cat.description?.isNotEmpty == true ? cat.description! : 'Sin descripción',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    adminEditButton(onPressed: () => _showCategoryForm(cat)),
                    adminStatusSwitch(
                      value: cat.isActive,
                      onChanged: (val) => provider.toggleCategoryStatus(cat.id!, !val),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
