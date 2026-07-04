import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/providers/projects_provider.dart';
import '../../data/models/project_model.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().fetchProjects();
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

  void _showProjectForm([ProjectModel? project]) {
    final isEditing = project != null;
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController = TextEditingController(text: project?.description ?? '');
    final startDateController = TextEditingController(text: project?.startDate ?? '');
    final endDateController = TextEditingController(text: project?.endDate ?? '');
    String status = project?.status ?? 'active';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (context, setState) {
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
                            isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        controller: nameController,
                        label: 'Nombre del Proyecto',
                        hint: 'Ej. Instalación Solar Planta Norte',
                        icon: Icons.business_center_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: descController,
                        label: 'Descripción (Opcional)',
                        hint: 'Ej. Montaje y conexión de 50 paneles',
                        icon: Icons.description_outlined,
                        isDark: isDark,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: startDateController,
                              label: 'Fecha Inicio (Opcional)',
                              hint: 'Ej. 2026-01-01',
                              icon: Icons.date_range_outlined,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              controller: endDateController,
                              label: 'Fecha Fin (Opcional)',
                              hint: 'Ej. 2026-12-31',
                              icon: Icons.date_range_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.black54,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.flag_outlined, color: isDark ? Colors.grey.shade400 : Colors.black87, size: 20),
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
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Activo')),
                          DropdownMenuItem(value: 'completed', child: Text('Completado')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            status = val!;
                          });
                        },
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
                                  final newProject = ProjectModel(
                                    id: project?.id,
                                    name: nameController.text.trim(),
                                    description: descController.text.trim(),
                                    startDate: startDateController.text.trim(),
                                    endDate: endDateController.text.trim(),
                                    status: status,
                                  );
                                  
                                  if (isEditing) {
                                    context.read<ProjectsProvider>().updateProject(newProject);
                                  } else {
                                    context.read<ProjectsProvider>().addProject(newProject);
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
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Activo';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Gestión de Proyectos'),
      floatingActionButton: adminFab(
        context: context,
        onPressed: () => _showProjectForm(),
        label: 'Nuevo Proyecto',
      ),
      body: Consumer<ProjectsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.projects.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.business_center_outlined,
              title: 'No hay proyectos registrados',
              subtitle: 'Crea proyectos para asociar salidas de materiales.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.projects.length,
            itemBuilder: (context, index) {
              final proj = provider.projects[index];
              final color = _statusColor(proj.status);

              return AdminListCard(
                icon: Icons.business_center_outlined,
                iconColor: color,
                iconBackground: color.withValues(alpha: 0.12),
                title: proj.name,
                subtitle: '${_statusLabel(proj.status)}${proj.startDate != null ? ' · ${proj.startDate}' : ''}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: proj)),
                  );
                },
                trailing: adminEditButton(onPressed: () => _showProjectForm(proj)),
              );
            },
          );
        },
      ),
    );
  }
}
