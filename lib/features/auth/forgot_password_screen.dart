import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/custom_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendPasswordResetCode(_emailController.text.trim());

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Se ha enviado un código de recuperación a tu correo.',
        );
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Error al enviar el código: ${e.toString().replaceAll('Exception: ', '')}',
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyAndReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.verifyCodeAndResetPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          '¡Contraseña actualizada exitosamente!',
        );
        context.pop(); // Regresar al Login
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Error al restablecer la contraseña: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.iconGlow(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SvgPicture.asset(
                          'assets/icon.svg',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    _codeSent ? 'Ingresa tu Código' : 'Restablecer Contraseña',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent 
                      ? 'Revisa tu correo y escribe el código de 6 dígitos para crear tu nueva contraseña.\\n(En caso de no visualizar el correo, por favor revisar en la bandeja de spam)' 
                      : 'Ingresa tu correo registrado para recibir un código de recuperación',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 32),

                  if (!_codeSent) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El correo es obligatorio';
                        }
                        if (!value.contains('@')) {
                          return 'Ingrese un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _handleSendCode,
                            icon: const Icon(Icons.send_rounded),
                            label: const Text(
                              'Enviar Código',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ] else ...[
                    TextFormField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El código es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La contraseña es obligatoria';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _handleVerifyAndReset,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'Actualizar Contraseña',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
