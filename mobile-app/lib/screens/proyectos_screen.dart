import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  List<dynamic> _proyectos = [];
  List<dynamic> _filtrados = [];
  bool _loading = true;
  String _filtroCarrera = 'Todos';
  final _busquedaCtrl = TextEditingController();

  static const List<String> _filtros = ['Todos', 'ISC', 'IIA', 'IID', 'IME'];

  @override
  void initState() {
    super.initState();
    _cargar();
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getProyectos();
      if (res['ok'] == true) {
        _proyectos = res['data'] as List? ?? [];
        _filtrar();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _filtrar() {
    final q = _busquedaCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _proyectos.where((p) {
        final matchCarrera = _filtroCarrera == 'Todos' ||
            (p['carreras_destino']?.toString().contains(_filtroCarrera) ?? false);
        final matchQ = q.isEmpty ||
            (p['nombre']?.toString().toLowerCase().contains(q) ?? false) ||
            (p['empresa']?.toString().toLowerCase().contains(q) ?? false);
        return matchCarrera && matchQ;
      }).toList();
    });
  }

  void _setFiltro(String f) {
    _filtroCarrera = f;
    _filtrar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Proyectos disponibles', style: AppTextStyles.heading1),
              const SizedBox(height: 14),
              // Buscador
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _busquedaCtrl,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'Buscar proyecto o empresa...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Chips de filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filtros.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f,
                      selected: _filtroCarrera == f,
                      onTap: () => _setFiltro(f),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 4),
            ]),
          ),
          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtrados.isEmpty
                ? const EmptyState(
              icon: Icons.work_outline,
              title: 'Sin proyectos',
              subtitle: 'No hay proyectos disponibles para los filtros seleccionados',
            )
                : RefreshIndicator(
              onRefresh: _cargar,
              color: AppColors.primary,
              backgroundColor: AppColors.darkCard,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _filtrados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ProyectoCard(
                  proyecto: _filtrados[i],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          ProyectoDetalleScreen(proyecto: _filtrados[i]))),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.darkBorder),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.darkBg : AppColors.textSecondary,
        )),
      ),
    );
  }
}

// ── Proyecto Card ─────────────────────────────────────────────────────────────
class _ProyectoCard extends StatelessWidget {
  final Map<String, dynamic> proyecto;
  final VoidCallback onTap;
  const _ProyectoCard({required this.proyecto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lugares = proyecto['lugares_disponibles'] ?? 0;
    final total   = proyecto['total_lugares'] ?? 3;
    final tags    = (proyecto['tecnologias']?.toString().split(',') ?? [])
        .map((t) => t.trim()).where((t) => t.isNotEmpty).take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(proyecto['empresa']?.toString() ?? 'Empresa',
              style: AppTextStyles.company),
          const SizedBox(height: 4),
          Text(proyecto['nombre']?.toString() ?? 'Proyecto',
              style: AppTextStyles.heading3),
          if (proyecto['descripcion'] != null) ...[
            const SizedBox(height: 4),
            Text(proyecto['descripcion'].toString(),
                style: AppTextStyles.bodySecondary,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          if (tags.isNotEmpty) ...[
            Wrap(spacing: 6, runSpacing: 6,
                children: tags.map((t) => TechChip(t)).toList()),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Text('$lugares/$total lugares',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Detalles', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkBg)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Proyecto Detalle ──────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class ProyectoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  const ProyectoDetalleScreen({super.key, required this.proyecto});

  @override
  State<ProyectoDetalleScreen> createState() => _ProyectoDetalleScreenState();
}

class _ProyectoDetalleScreenState extends State<ProyectoDetalleScreen> {
  bool _postulando = false;
  Map<String, dynamic>? _detalle;
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargarDetalle(); }

  Future<void> _cargarDetalle() async {
    try {
      final res = await ApiService.getProyecto(widget.proyecto['id_proyecto']);
      if (res['ok'] == true && mounted) setState(() => _detalle = res['data']);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _postular() async {
    setState(() => _postulando = true);
    try {
      final res = await ApiService.postular(widget.proyecto['id_proyecto']);
      if (mounted) {
        if (res['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Postulación enviada exitosamente!'),
            backgroundColor: AppColors.statusAccepted,
          ));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Error al postularse'),
            backgroundColor: AppColors.statusRejected,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: AppColors.statusRejected,
        ));
      }
    }
    if (mounted) setState(() => _postulando = false);
  }

  @override
  Widget build(BuildContext context) {
    // Usa el detalle completo si ya cargó, si no usa los datos del listado
    final p = _detalle ?? widget.proyecto;
    final numAlumnos = p['num_alumnos'] ?? p['total_lugares'] ?? 3;
    final aceptados  = p['alumnos_aceptados'] ?? 0;
    final lugares    = numAlumnos - aceptados;
    final lleno      = lugares <= 0;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
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
                      color: AppColors.darkCard, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder)),
                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['empresa']?.toString() ?? '', style: AppTextStyles.company),
                Text(p['nombre']?.toString() ?? 'Proyecto', style: AppTextStyles.heading2,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),

          // Badges de info rápida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _InfoBadge(
                icon: Icons.people_rounded,
                label: '$lugares/$numAlumnos lugares',
                color: lleno ? AppColors.statusRejected : AppColors.primary,
              ),
              if (p['modalidad'] != null)
                _InfoBadge(icon: Icons.work_rounded, label: p['modalidad'].toString()),
              if (p['area'] != null)
                _InfoBadge(icon: Icons.category_rounded, label: p['area'].toString()),
            ]),
          ),
          const SizedBox(height: 12),

          // Contenido scrollable
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                if (p['descripcion'] != null)
                  _InfoSection(title: 'Descripción del proyecto',
                      content: p['descripcion'].toString()),
                if (p['requisitos'] != null && p['requisitos'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoSection(title: 'Requisitos',
                      content: p['requisitos'].toString()),
                ],
                if (p['nombre_responsable'] != null || p['correo_responsable'] != null) ...[
                  const SizedBox(height: 12),
                  _ContactoSection(
                    responsable: p['nombre_responsable']?.toString(),
                    correo: p['correo_responsable']?.toString() ?? p['correo_empresa']?.toString(),
                  ),
                ],
                if (p['asesor'] != null && p['asesor'].toString() != 'Sin asignar') ...[
                  const SizedBox(height: 12),
                  _InfoSection(title: 'Asesor externo', content: p['asesor'].toString()),
                ],
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // Botones
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: [
              PrimaryButton(
                label: lleno ? 'Sin lugares disponibles' : 'POSTULARME',
                loading: _postulando,
                onPressed: lleno ? null : _postular,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.darkBorder),
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Regresar al catálogo'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoBadge({required this.icon, required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _ContactoSection extends StatelessWidget {
  final String? responsable;
  final String? correo;
  const _ContactoSection({this.responsable, this.correo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.darkCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contacto en la empresa', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (responsable != null) ...[
          Row(children: [
            const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(responsable!, style: AppTextStyles.body),
          ]),
          const SizedBox(height: 6),
        ],
        if (correo != null)
          Row(children: [
            const Icon(Icons.email_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(correo!, style: AppTextStyles.body)),
          ]),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text(content, style: AppTextStyles.bodySecondary),
      ]),
    );
  }
}