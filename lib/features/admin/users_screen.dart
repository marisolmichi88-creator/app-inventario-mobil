import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/providers/users_provider.dart';
import '../../data/models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchUsers();
    });
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: (val) {
        if (!enabled) return null;
        if (val == null || val.isEmpty) return 'Requerido';
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

  void _showUserForm([UserModel? user]) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    String? selectedRole = user?.role;
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
                            isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
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
                        label: 'Nombre completo',
                        hint: 'Nombre y Apellido',
                        icon: Icons.person_outline,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: emailController,
                        label: 'Correo electrónico',
                        hint: 'correo@gmail.com',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        _buildFormField(
                          controller: passwordController,
                          label: 'Contraseña',
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        hint: const Text('Seleccionar rol'),
                        validator: (val) => val == null ? 'Por favor selecciona un rol' : null,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.black54,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.badge_outlined, color: isDark ? Colors.grey.shade400 : Colors.black87, size: 20),
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
                          DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                          DropdownMenuItem(value: 'operador', child: Text('Trabajador')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedRole = val;
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
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    try {
                                      final newUser = UserModel(
                                        id: user?.id,
                                        authUserId: user?.authUserId,
                                        name: nameController.text.trim(),
                                        email: emailController.text.trim(),
                                        password: passwordController.text.trim(),
                                        role: selectedRole!,
                                        isActive: user?.isActive ?? true,
                                      );
                                      
                                      if (isEditing) {
                                        await context.read<UsersProvider>().updateUser(newUser);
                                      } else {
                                        await context.read<UsersProvider>().addUser(newUser);
                                      }
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
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
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar Usuario'),
                                  content: const Text('¿Estás seguro de que deseas eliminar este usuario?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                try {
                                  await context.read<UsersProvider>().deleteUser(user!.id!);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar Usuario', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Gestión de Usuarios'),
      floatingActionButton: adminFab(
        context: context,
        onPressed: () => _showUserForm(),
        label: 'Nuevo Usuario',
      ),
      body: Consumer<UsersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.users.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.people_outline,
              title: 'No hay usuarios registrados',
              subtitle: 'Pulsa el botón inferior para crear el primero.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              final isAdmin = user.role == 'admin';

              return AdminListCard(
                icon: isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                iconColor: user.isActive
                    ? (isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6))
                    : const Color(0xFFEF4444),
                iconBackground: user.isActive
                    ? (isAdmin
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.12))
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                title: user.name,
                subtitle: '${user.email} · ${isAdmin ? 'Administrador' : 'Trabajador'}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    adminEditButton(onPressed: () => _showUserForm(user)),
                    adminStatusSwitch(
                      value: user.isActive,
                      onChanged: (val) => provider.toggleUserStatus(user.id!, !val),
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
