import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_correoCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(children: [
        // Fondo degradado
        Positioned(
          top: 0, left: 0, right: 0, height: 320,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF003D22), AppColors.darkBg],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 60),
              // Logo / título
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 18),
              Text('SIGERP', style: AppTextStyles.heading1.copyWith(
                color: AppColors.primary, fontSize: 28, letterSpacing: 2,
              )),
              const SizedBox(height: 4),
              Text('Iniciar sesión', style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w400, fontSize: 18,
              )),
              const SizedBox(height: 48),

              // Card del formulario
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(children: [
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => auth.error != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorBanner(auth.error!),
                        )
                      : const SizedBox.shrink(),
                  ),
                  AppTextField(
                    label: 'Correo institucional',
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'usuario@itl.edu.mx',
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary, size: 20,
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => PrimaryButton(
                      label: 'Entrar',
                      loading: auth.loading,
                      onPressed: _login,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('¿No tienes cuenta? ', style: AppTextStyles.bodySecondary),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('Regístrate aquí',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600,
                    )),
                ),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }
}
