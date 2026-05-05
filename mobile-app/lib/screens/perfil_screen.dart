import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _perfil;
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPerfil();
      if (res['ok'] == true && mounted) _perfil = res['data'];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Cerrar sesión', style: AppTextStyles.heading3),
        content: const Text('¿Estás seguro que deseas cerrar sesión?',
          style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
              style: TextStyle(color: AppColors.statusRejected)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppColors.primary,
              backgroundColor: AppColors.darkCard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  // Header con avatar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF003D22), AppColors.darkBg],
                      ),
                    ),
                    child: Column(children: [
                      // Avatar
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _initials(usuario?['nombre'] ?? ''),
                            style: const TextStyle(
                              color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(usuario?['nombre'] ?? '', style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text(usuario?['correo'] ?? '', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 10),
                      if (_perfil?['matricula'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Text(
                            '${_perfil!['matricula']} · ${_perfil!['carrera'] ?? ''}',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // Info card
                      _InfoCard(titulo: 'Información personal', items: [
                        if (_perfil?['nombre'] != null)
                          _InfoItem(label: 'Nombre completo', value: _perfil!['nombre'].toString()),
                        if (_perfil?['correo'] != null)
                          _InfoItem(label: 'Correo institucional', value: _perfil!['correo'].toString()),
                        if (_perfil?['matricula'] != null)
                          _InfoItem(label: 'Matrícula', value: _perfil!['matricula'].toString()),
                        if (_perfil?['carrera'] != null)
                          _InfoItem(label: 'Carrera', value: _perfil!['carrera'].toString()),
                      ]),

                      const SizedBox(height: 16),

                      // Botón cerrar sesión
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded,
                            color: AppColors.statusRejected, size: 18),
                          label: const Text('Cerrar sesión',
                            style: TextStyle(color: AppColors.statusRejected,
                              fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.statusRejected, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ]),
              ),
            ),
      ),
    );
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo;
  final List<_InfoItem> items;
  const _InfoCard({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: AppTextStyles.heading3),
        const SizedBox(height: 14),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.label.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(item.value, style: AppTextStyles.body),
          ]),
        )),
      ]),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}
