import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _showProjectForm([ProjectModel? project]) {
    final isEditing = project != null;
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController = TextEditingController(text: project?.description ?? '');
    final startDateController = TextEditingController(text: project?.startDate ?? '');
    final endDateController = TextEditingController(text: project?.endDate ?? '');
    String status = project?.status ?? 'active';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre del Proyecto'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: startDateController,
                        decoration: const InputDecoration(labelText: 'Fecha Inicio (ej. 2026-01-01)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endDateController,
                        decoration: const InputDecoration(labelText: 'Fecha Fin (ej. 2026-12-31)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Estado'),
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
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proyectos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProjectsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.projects.isEmpty) {
            return const Center(child: Text('No hay proyectos registrados.'));
          }

          return ListView.builder(
            itemCount: provider.projects.length,
            itemBuilder: (context, index) {
              final proj = provider.projects[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: proj.status == 'active' ? Colors.purple.shade100 : Colors.grey.shade300,
                  child: Icon(
                    Icons.business_center,
                    color: proj.status == 'active' ? Colors.purple.shade900 : Colors.grey.shade700,
                  ),
                ),
                title: Text(proj.name),
                subtitle: Text('${proj.status.toUpperCase()} ${proj.startDate != null ? '(${proj.startDate})' : ''}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: proj)),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showProjectForm(proj),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
