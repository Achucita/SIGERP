import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? _proyectoActivo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPerfil();
      if (res['ok'] == true) {
        _perfil = res['data'];
      }
      // Intentar obtener postulaciones para ver si hay proyecto activo
      final postRes = await ApiService.getMisPostulaciones();
      if (postRes['ok'] == true) {
        final lista = postRes['data'] as List? ?? [];
        final aceptada = lista.firstWhere(
          (p) => p['estado']?.toString().toLowerCase() == 'aceptada',
          orElse: () => null,
        );
        if (aceptada != null) {
          _proyectoActivo = aceptada;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _cargar,
            color: AppColors.primary,
            backgroundColor: AppColors.darkCard,
            child: CustomScrollView(slivers: [
              // AppBar con degradado
              SliverAppBar(
                pinned: false,
                floating: true,
                backgroundColor: AppColors.darkBg,
                expandedHeight: 160,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF003D22), AppColors.darkBg],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('ALUMNO',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hola, ${usuario?['nombre']?.toString().split(' ').first ?? ''}',
                          style: AppTextStyles.heading1,
                        ),
                        if (_perfil?['matricula'] != null)
                          Text(
                            '${_perfil!['matricula']} · ${_perfil!['carrera'] ?? ''}',
                            style: AppTextStyles.bodySecondary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  // Proyecto activo
                  if (_proyectoActivo != null) ...[
                    Text('MI PROYECTO ACTIVO', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    _ProyectoActivoCard(postulacion: _proyectoActivo!),
                    const SizedBox(height: 24),
                  ],

                  // Accesos rápidos
                  Text('ACCESOS RÁPIDOS', style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _QuickCard(
                        icon: Icons.list_alt_rounded,
                        label: 'Ver proyectos',
                        onTap: () => _goTo(context, 1),
                      ),
                      _QuickCard(
                        icon: Icons.upload_file_rounded,
                        label: 'Subir anteproyecto',
                        onTap: () => _goTo(context, 2),
                      ),
                      _QuickCard(
                        icon: Icons.send_rounded,
                        label: 'Postulaciones',
                        onTap: () => Navigator.pushNamed(context, '/postulaciones'),
                      ),
                      _QuickCard(
                        icon: Icons.assignment_rounded,
                        label: 'Subir reporte',
                        onTap: () => _goTo(context, 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ])),
              ),
            ]),
          ),
    );
  }

  void _goTo(BuildContext context, int index) {
    MainShell.goToTab(context, index);
  }
}

// ── Proyecto activo card ──────────────────────────────────────────────────────
class _ProyectoActivoCard extends StatelessWidget {
  final Map<String, dynamic> postulacion;
  const _ProyectoActivoCard({required this.postulacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(postulacion['empresa']?.toString() ?? 'Empresa',
          style: AppTextStyles.company),
        const SizedBox(height: 4),
        Text(postulacion['proyecto']?.toString() ?? 'Proyecto',
          style: AppTextStyles.heading3),
        const SizedBox(height: 10),
        Text('Avance', style: AppTextStyles.label),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (postulacion['avance'] ?? 0) / 100.0,
            backgroundColor: AppColors.darkBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        if (postulacion['asesor_interno'] != null)
          GestureDetector(
            child: Text('Asesor interno',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.accent,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accent,
              )),
          ),
      ]),
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}