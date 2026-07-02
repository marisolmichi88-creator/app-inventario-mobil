import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _showUserForm([UserModel? user]) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    String selectedRole = user?.role ?? 'worker';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                          DropdownMenuItem(value: 'worker', child: Text('Trabajador')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedRole = val!;
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
                      final newUser = UserModel(
                        id: user?.id,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        role: selectedRole,
                        isActive: user?.isActive ?? true,
                      );
                      
                      if (isEditing) {
                        context.read<UsersProvider>().updateUser(newUser);
                      } else {
                        context.read<UsersProvider>().addUser(newUser);
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
        title: const Text('Gestión de Usuarios'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<UsersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return ListView.builder(
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isActive ? Colors.blue.shade100 : Colors.red.shade100,
                  child: Icon(
                    user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: user.isActive ? Colors.blue.shade900 : Colors.red.shade900,
                  ),
                ),
                title: Text(user.name),
                subtitle: Text('${user.email} - ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUserForm(user),
                    ),
                    Switch(
                      value: user.isActive,
                      onChanged: (val) {
                        provider.toggleUserStatus(user.id!, !val);
                      },
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
