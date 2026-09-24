// ignore_for_file: unnecessary_non_null_assertion
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/providers/users_provider.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';

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
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: (val) {
        if (!enabled) return null;
        if (val == null || val.isEmpty) return 'Requerido';
        if (isEmail &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val.trim())) {
          return 'Correo inválido';
        }
        if (isPassword && val.length < 8) {
          return 'Usa al menos 8 caracteres';
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

  Widget _buildLoadError(UsersProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFF87171),
            ),
            const SizedBox(height: 20),
            Text(
              'No se pudo cargar la lista de usuarios',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              provider.loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.fetchUsers,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteUser(UserModel user) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFEF4444),
          size: 32,
        ),
        title: const Text('¿Eliminar a este usuario?'),
        content: Text(
          'Se borrará la cuenta de ${user.email} junto con su ficha. No podrá '
          'volver a iniciar sesión y no se puede deshacer.\n\n'
          'Si solo quieres que deje de entrar por un tiempo, usa el '
          'interruptor de la lista en lugar de eliminarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _toggleStatus(
    UsersProvider provider,
    UserModel user,
    bool value,
  ) async {
    try {
      await provider.toggleUserStatus(user.id!, !value);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, UsersProvider.describeError(e));
    }
  }

  void _showConfirmationNotice(String email) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_unread_rounded,
          color: Color(0xFF3B82F6),
          size: 32,
        ),
        title: const Text('Falta confirmar el correo'),
        content: Text(
          'La cuenta de $email quedó creada, pero Supabase exige confirmar el '
          'correo antes del primer ingreso. Pídele que abra el enlace que le '
          'llegó; hasta entonces la app le dirá que su correo no está '
          'confirmado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showUserForm([UserModel? user]) {
    final isEditing = user != null;
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController(
      text: user?.password ?? '',
    );
    String? selectedRole = user?.role;
    if (selectedRole != null && selectedRole != 'admin') {
      selectedRole = 'operador';
    }
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    // El error se muestra dentro de la hoja. Un SnackBar se dibuja en el
    // Scaffold, por debajo del modal, así que el administrador nunca lo veía.
    String? errorMessage;

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        _buildFormField(
                          controller: passwordController,
                          label: 'Contraseña',
                          hint: 'Mínimo 8 caracteres',
                          icon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        hint: const Text('Seleccionar rol'),
                        validator: (val) =>
                            val == null ? 'Por favor selecciona un rol' : null,
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black87,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'operador',
                            child: Text('Trabajador'),
                          ),
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
                      if (errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF87171),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_rounded,
                                color: Color(0xFFF87171),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SelectableText(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFFECACA)
                                        : const Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (isEditing && user!.id != currentUserId) ...[
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final confirmado =
                                        await _confirmDeleteUser(user);
                                    if (!confirmado || !context.mounted) return;
                                    setState(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                    });
                                    try {
                                      await context
                                          .read<UsersProvider>()
                                          .deleteUser(user.id!);
                                      if (context.mounted) {
                                        CustomSnackBar.showSuccess(
                                          context,
                                          'Usuario eliminado',
                                        );
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setState(() {
                                          isSubmitting = false;
                                          errorMessage =
                                              UsersProvider.describeError(e);
                                        });
                                      }
                                    }
                                  },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            label: const Text('Eliminar usuario'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF1959AD),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        setState(() {
                                          isSubmitting = true;
                                          errorMessage = null;
                                        });
                                        try {
                                          final newUser = UserModel(
                                            id: user?.id,
                                            authUserId: user?.authUserId,
                                            name: nameController.text.trim(),
                                            email: emailController.text.trim(),
                                            password: passwordController.text
                                                .trim(),
                                            role: selectedRole!,
                                            isActive: user?.isActive ?? true,
                                          );

                                          String successMessage;
                                          var needsConfirmation = false;
                                          if (isEditing) {
                                            await context
                                                .read<UsersProvider>()
                                                .updateUser(newUser);
                                            successMessage =
                                                'Usuario actualizado';
                                          } else {
                                            final result = await context
                                                .read<UsersProvider>()
                                                .addUser(newUser);
                                            needsConfirmation = result
                                                .requiresEmailConfirmation;
                                            successMessage = needsConfirmation
                                                ? 'Cuenta creada. El usuario debe confirmar el correo antes de ingresar.'
                                                : 'Cuenta creada y lista para ingresar.';
                                          }
                                          if (context.mounted) {
                                            setState(
                                              () => isSubmitting = false,
                                            );
                                            CustomSnackBar.showSuccess(
                                              context,
                                              successMessage,
                                            );
                                            Navigator.pop(context);
                                            // Un aviso de 3 segundos se pierde,
                                            // y sin confirmar el correo la
                                            // cuenta nueva no puede entrar.
                                            if (needsConfirmation) {
                                              _showConfirmationNotice(
                                                newUser.email,
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            setState(() {
                                              isSubmitting = false;
                                              errorMessage =
                                                  UsersProvider.describeError(
                                                    e,
                                                  );
                                            });
                                          }
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF1959AD),
                                foregroundColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: isSubmitting
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
                                isSubmitting ? 'Guardando...' : 'Guardar',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
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

          if (provider.loadError != null) {
            return _buildLoadError(provider);
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
                icon: isAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline,
                iconColor: user.isActive
                    ? (isAdmin
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF3B82F6))
                    : const Color(0xFFEF4444),
                iconBackground: user.isActive
                    ? (isAdmin
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.12))
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                title: user.name,
                subtitle:
                    '${user.email} · ${isAdmin ? 'Administrador' : 'Trabajador'}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    adminEditButton(onPressed: () => _showUserForm(user)),
                    adminStatusSwitch(
                      value: user.isActive,
                      onChanged: user.id == currentUserId
                          ? null
                          : (val) => _toggleStatus(provider, user, val),
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
