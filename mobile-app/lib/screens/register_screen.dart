import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl    = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _correoCtrl    = TextEditingController();
  final _passCtrl      = TextEditingController();
  String? _carrera;
  bool _showPass = false;

  static const List<String> _carreras = [
    'ISC', 'IIA', 'IID', 'IME', 'ICE', 'IGE', 'IBI',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose(); _matriculaCtrl.dispose();
    _correoCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _registro() async {
    if (_carrera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu carrera'), backgroundColor: AppColors.statusRejected));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.registro(
      nombre: _nombreCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      contrasena: _passCtrl.text,
      matricula: _matriculaCtrl.text.trim(),
      carrera: _carrera!,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Inicia sesión.'),
          backgroundColor: AppColors.statusAccepted,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0, height: 200,
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
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('NUEVO USUARIO',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text('Crear cuenta', style: AppTextStyles.heading2),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => auth.error != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorBanner(auth.error!),
                        )
                      : const SizedBox.shrink(),
                  ),
                  AppTextField(label: 'Nombre completo', controller: _nombreCtrl),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Matrícula', controller: _matriculaCtrl,
                    keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  AppDropdown(
                    label: 'Carrera',
                    value: _carrera,
                    items: _carreras,
                    onChanged: (v) => setState(() => _carrera = v),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Correo institucional',
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'usuario@itl.edu.mx',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary, size: 20),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => PrimaryButton(
                      label: 'Crear cuenta',
                      loading: auth.loading,
                      onPressed: _registro,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('¿Ya tienes cuenta? ', style: AppTextStyles.bodySecondary),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Iniciar sesión',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
