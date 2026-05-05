import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class TramitesScreen extends StatefulWidget {
  const TramitesScreen({super.key});

  @override
  State<TramitesScreen> createState() => _TramitesScreenState();
}

class _TramitesScreenState extends State<TramitesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('Trámites', style: AppTextStyles.heading1)),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(text: 'Postulaciones'),
              Tab(text: 'Anteproyecto'),
              Tab(text: 'Reportes'),
              Tab(text: 'Evidencias'),
              Tab(text: 'Documentos'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                PostulacionesTab(),
                AnteproyectoTab(),
                ReportesTab(),
                EvidenciasTab(),
                DocumentosTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 1: Postulaciones — solo lista, sin estados de aceptar/rechazar
// ═══════════════════════════════════════════════════════════════════════
class PostulacionesTab extends StatefulWidget {
  const PostulacionesTab({super.key});
  @override State<PostulacionesTab> createState() => _PostulacionesTabState();
}

class _PostulacionesTabState extends State<PostulacionesTab> {
  List<dynamic> _lista = [];
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMisPostulaciones();
      if (res['ok'] == true && mounted) _lista = res['data'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_lista.isEmpty) return const EmptyState(
      icon: Icons.send_rounded,
      title: 'Sin postulaciones',
      subtitle: 'Ve a "Proyectos" y postúlate a uno para comenzar.',
    );
    return RefreshIndicator(
      onRefresh: _cargar, color: AppColors.primary, backgroundColor: AppColors.darkCard,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = _lista[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['proyecto']?.toString() ?? '', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(p['empresa']?.toString() ?? '', style: AppTextStyles.company),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(_fecha(p['fecha_postulacion']?.toString() ?? ''),
                  style: AppTextStyles.caption),
                if (p['asesor_interno'] != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(p['asesor_interno'].toString(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ],
              ]),
            ]),
          );
        },
      ),
    );
  }

  String _fecha(String f) {
    try { final d = DateTime.parse(f); return '${d.day}/${d.month}/${d.year}'; }
    catch (_) { return f; }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 2: Anteproyecto
// ═══════════════════════════════════════════════════════════════════════
class AnteproyectoTab extends StatefulWidget {
  const AnteproyectoTab({super.key});
  @override State<AnteproyectoTab> createState() => _AnteproyectoTabState();
}

class _AnteproyectoTabState extends State<AnteproyectoTab> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  File? _archivo; String? _nombreArchivo;
  bool _subiendo = false;
  List<dynamic> _postulaciones = [];
  int? _idPost;
  Map<String, dynamic>? _antep;
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }
  @override void dispose() { _tituloCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMisPostulaciones();
      if (res['ok'] == true && mounted) {
        _postulaciones = res['data'] as List? ?? [];
        if (_postulaciones.isNotEmpty) {
          _idPost ??= _postulaciones.first['id_postulacion'];
          await _cargarAntep();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarAntep() async {
    if (_idPost == null) return;
    try {
      final res = await ApiService.getMiAnteproyecto(_idPost!);
      setState(() => _antep = res['ok'] == true ? res['data'] : null);
    } catch (_) { setState(() => _antep = null); }
  }

  Future<void> _selArchivo() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    if (r?.files.single.path != null && mounted)
      setState(() { _archivo = File(r!.files.single.path!); _nombreArchivo = r.files.single.name; });
  }

  Future<void> _subir() async {
    if (_archivo == null || _tituloCtrl.text.trim().isEmpty) {
      _snack('Título y archivo son requeridos', error: true); return;
    }
    setState(() => _subiendo = true);
    try {
      final res = await ApiService.subirAnteproyecto(
        idPostulacion: _idPost!, archivo: _archivo!,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );
      if (mounted) {
        if (res['ok'] == true) {
          _snack('Anteproyecto enviado');
          setState(() { _archivo = null; _nombreArchivo = null; });
          _tituloCtrl.clear(); _descCtrl.clear();
          await _cargarAntep();
        } else { _snack(res['message'] ?? 'Error', error: true); }
      }
    } catch (_) {}
    if (mounted) setState(() => _subiendo = false);
  }

  void _snack(String m, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m),
      backgroundColor: error ? AppColors.statusRejected : AppColors.statusAccepted));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_postulaciones.isEmpty) return const EmptyState(
      icon: Icons.upload_file_rounded,
      title: 'Sin postulaciones',
      subtitle: 'Primero postúlate a un proyecto.',
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_antep != null) ...[_AntepStatusCard(antep: _antep!), const SizedBox(height: 20)],
        if (_postulaciones.length > 1) ...[
          SectionLabel('Proyecto'),
          _DropdownPost(
            postulaciones: _postulaciones, value: _idPost,
            onChanged: (v) { setState(() { _idPost = v; _antep = null; }); _cargarAntep(); }),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_antep != null ? 'Reenviar anteproyecto' : 'Subir anteproyecto',
              style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            AppTextField(label: 'Título', controller: _tituloCtrl, hint: 'Título del anteproyecto'),
            const SizedBox(height: 14),
            AppTextField(label: 'Descripción (opcional)', controller: _descCtrl, hint: '...'),
            const SizedBox(height: 14),
            _PickerArchivo(archivo: _archivo, nombre: _nombreArchivo,
              extensiones: ['pdf', 'docx'], onTap: _selArchivo),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Enviar anteproyecto', loading: _subiendo,
              onPressed: _archivo != null ? _subir : null),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 3: Reportes formales → Admin, con periodos de fecha
// ═══════════════════════════════════════════════════════════════════════
class ReportesTab extends StatefulWidget {
  const ReportesTab({super.key});
  @override State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab> {
  List<dynamic> _reportes  = [];
  List<dynamic> _periodos  = [];
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final r1 = await ApiService.getMisReportes();
      final r2 = await ApiService.getPeriodos();
      if (mounted) {
        if (r1['ok'] == true) _reportes = r1['data'] as List? ?? [];
        if (r2['ok'] == true) _periodos = r2['data'] as List? ?? [];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic>? _reportePorNumero(int n) {
    try { return _reportes.firstWhere((r) => r['numero_reporte'].toString() == n.toString()); }
    catch (_) { return null; }
  }

  Map<String, dynamic>? _periodoPorNumero(int n) {
    try { return _periodos.firstWhere((p) => p['numero_reporte'].toString() == n.toString()); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(
      onRefresh: _cargar, color: AppColors.primary, backgroundColor: AppColors.darkCard,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Reportes de avance', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text('El administrador habilitará cada periodo en la fecha correspondiente.',
            style: AppTextStyles.bodySecondary),
          const SizedBox(height: 20),
          for (int n = 1; n <= 3; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PeriodoCard(
                numero: n,
                periodo: _periodoPorNumero(n),
                reporte: _reportePorNumero(n),
                onEnviado: _cargar,
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodoCard extends StatefulWidget {
  final int numero;
  final Map<String, dynamic>? periodo;
  final Map<String, dynamic>? reporte;
  final VoidCallback onEnviado;
  const _PeriodoCard({required this.numero, this.periodo, this.reporte, required this.onEnviado});
  @override State<_PeriodoCard> createState() => _PeriodoCardState();
}

class _PeriodoCardState extends State<_PeriodoCard> {
  bool _expandido = false;
  final _periodoCtrl = TextEditingController();
  final _comentCtrl  = TextEditingController();
  File? _archivo; String? _nombreArchivo;
  bool _subiendo = false;

  @override void dispose() { _periodoCtrl.dispose(); _comentCtrl.dispose(); super.dispose(); }

  bool get _abierto => widget.periodo?['estado_periodo'] == 'abierto';
  bool get _yaEnviado => widget.reporte != null;

  Future<void> _subir() async {
    if (_archivo == null || _periodoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa el periodo y adjunta el PDF'),
        backgroundColor: AppColors.statusRejected)); return;
    }
    setState(() => _subiendo = true);
    try {
      final res = await ApiService.subirReporte(
        numeroReporte: widget.numero, periodoCubre: _periodoCtrl.text,
        archivo: _archivo!,
        comentarios: _comentCtrl.text.isNotEmpty ? _comentCtrl.text : null,
      );
      if (mounted) {
        if (res['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Reporte ${widget.numero} enviado'),
            backgroundColor: AppColors.statusAccepted));
          setState(() { _expandido = false; _archivo = null; _nombreArchivo = null; });
          _periodoCtrl.clear(); _comentCtrl.clear();
          widget.onEnviado();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Error'),
            backgroundColor: AppColors.statusRejected));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _subiendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.periodo?['nombre'] ?? 'Reporte ${widget.numero}';
    final estadoPeriodo = widget.periodo?['estado_periodo'] ?? 'no_habilitado';
    final estadoReporte = widget.reporte?['estado']?.toString();

    Color borderColor = AppColors.darkBorder;
    if (_yaEnviado) borderColor = estadoReporte == 'revisado'
      ? AppColors.statusAccepted : AppColors.statusPartial;

    return Container(
      decoration: BoxDecoration(color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Círculo de estado
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: _yaEnviado
                  ? AppColors.statusAccepted.withOpacity(0.15)
                  : _abierto ? AppColors.primary.withOpacity(0.1) : AppColors.darkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _yaEnviado
                  ? AppColors.statusAccepted.withOpacity(0.4)
                  : _abierto ? AppColors.primary.withOpacity(0.3) : AppColors.darkBorder)),
              child: Center(child: _yaEnviado
                ? const Icon(Icons.check_rounded, color: AppColors.statusAccepted, size: 22)
                : Text('R${widget.numero}', style: TextStyle(
                    color: _abierto ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700, fontSize: 13))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              _EstadoPeriodoChip(estado: estadoPeriodo),
              if (_yaEnviado && estadoReporte != null) ...[
                const SizedBox(height: 4),
                _EstadoReporteChip(estado: estadoReporte),
              ],
            ])),
            if (_abierto && !_yaEnviado)
              GestureDetector(
                onTap: () => setState(() => _expandido = !_expandido),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: Icon(_expandido ? Icons.keyboard_arrow_up : Icons.upload_rounded,
                    color: AppColors.primary, size: 20),
                ),
              ),
          ]),
        ),
        // Comentario admin si existe
        if (_yaEnviado && widget.reporte?['comentario_admin'] != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Comentario de administración:', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(widget.reporte!['comentario_admin'].toString(), style: AppTextStyles.bodySecondary),
              ])),
          ),
        // Formulario colapsable
        if (_abierto && !_yaEnviado && _expandido)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(), const SizedBox(height: 12),
              AppTextField(label: 'Periodo que cubre', controller: _periodoCtrl,
                hint: 'Ej: Enero - Febrero 2025'),
              const SizedBox(height: 12),
              AppTextField(label: 'Comentarios (opcional)', controller: _comentCtrl, hint: '...'),
              const SizedBox(height: 12),
              _PickerArchivo(archivo: _archivo, nombre: _nombreArchivo,
                extensiones: ['pdf'],
                onTap: () async {
                  final r = await FilePicker.platform.pickFiles(
                    type: FileType.custom, allowedExtensions: ['pdf']);
                  if (r?.files.single.path != null && mounted)
                    setState(() { _archivo = File(r!.files.single.path!); _nombreArchivo = r.files.single.name; });
                }),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Enviar reporte ${widget.numero}',
                loading: _subiendo, onPressed: _archivo != null ? _subir : null),
            ]),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 4: Evidencias → Asesor, siempre abierto
// ═══════════════════════════════════════════════════════════════════════
class EvidenciasTab extends StatefulWidget {
  const EvidenciasTab({super.key});
  @override State<EvidenciasTab> createState() => _EvidenciasTabState();
}

class _EvidenciasTabState extends State<EvidenciasTab> {
  final _descCtrl = TextEditingController();
  List<dynamic> _lista = [];
  bool _loading = true;
  File? _archivo; String? _nombreArchivo;
  bool _subiendo = false;

  @override void initState() { super.initState(); _cargar(); }
  @override void dispose() { _descCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMisEvidencias();
      if (res['ok'] == true && mounted) _lista = res['data'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selArchivo() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    if (r?.files.single.path != null && mounted)
      setState(() { _archivo = File(r!.files.single.path!); _nombreArchivo = r.files.single.name; });
  }

  Future<void> _subir() async {
    if (_archivo == null) { _snack('Selecciona un archivo', error: true); return; }
    setState(() => _subiendo = true);
    try {
      final res = await ApiService.subirEvidencia(
        archivo: _archivo!,
        descripcion: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );
      if (mounted) {
        if (res['ok'] == true) {
          _snack('Evidencia enviada al asesor');
          setState(() { _archivo = null; _nombreArchivo = null; });
          _descCtrl.clear();
          await _cargar();
        } else { _snack(res['message'] ?? 'Error', error: true); }
      }
    } catch (_) {}
    if (mounted) setState(() => _subiendo = false);
  }

  void _snack(String m, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m),
      backgroundColor: error ? AppColors.statusRejected : AppColors.statusAccepted));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(
      onRefresh: _cargar, color: AppColors.primary, backgroundColor: AppColors.darkCard,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Formulario para subir
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Enviar evidencia al asesor', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text('Puedes enviar archivos, fotos o cualquier avance en cualquier momento.',
                style: AppTextStyles.bodySecondary),
              const SizedBox(height: 16),
              AppTextField(label: 'Descripción (opcional)', controller: _descCtrl,
                hint: 'Ej: Avance semana 3, foto de instalación...'),
              const SizedBox(height: 14),
              _PickerArchivo(archivo: _archivo, nombre: _nombreArchivo,
                extensiones: null, onTap: _selArchivo),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Enviar evidencia', loading: _subiendo,
                onPressed: _archivo != null ? _subir : null),
            ]),
          ),
          const SizedBox(height: 20),
          // Historial
          if (_lista.isNotEmpty) ...[
            Text('HISTORIAL', style: AppTextStyles.label),
            const SizedBox(height: 12),
            ..._lista.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e['comentario_asesor'] != null
                      ? AppColors.primary.withOpacity(0.3) : AppColors.darkBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e['descripcion']?.toString() ?? 'Sin descripción',
                      style: AppTextStyles.body)),
                    Text(_fecha(e['fecha_envio']?.toString() ?? ''), style: AppTextStyles.caption),
                  ]),
                  if (e['comentario_asesor'] != null) ...[
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Comentario del asesor:', style: AppTextStyles.label.copyWith(
                          color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(e['comentario_asesor'].toString(), style: AppTextStyles.bodySecondary),
                      ])),
                  ],
                ]),
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _fecha(String f) {
    try { final d = DateTime.parse(f); return '${d.day}/${d.month}/${d.year}'; }
    catch (_) { return f; }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 5: Documentos — carpeta digital
// ═══════════════════════════════════════════════════════════════════════
class DocumentosTab extends StatefulWidget {
  const DocumentosTab({super.key});
  @override State<DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<DocumentosTab> {
  final _nombreCtrl = TextEditingController();
  List<dynamic> _lista = [];
  bool _loading = true;
  File? _archivo; String? _nombreArchivo;
  bool _subiendo = false;

  @override void initState() { super.initState(); _cargar(); }
  @override void dispose() { _nombreCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMisDocumentos();
      if (res['ok'] == true && mounted) _lista = res['data'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selArchivo() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    if (r?.files.single.path != null && mounted) {
      setState(() {
        _archivo = File(r!.files.single.path!);
        _nombreArchivo = r.files.single.name;
        if (_nombreCtrl.text.isEmpty) _nombreCtrl.text = r.files.single.name;
      });
    }
  }

  Future<void> _subir() async {
    if (_archivo == null || _nombreCtrl.text.trim().isEmpty) {
      _snack('Nombre y archivo son requeridos', error: true); return;
    }
    setState(() => _subiendo = true);
    try {
      final res = await ApiService.subirDocumento(
        archivo: _archivo!, nombre: _nombreCtrl.text.trim());
      if (mounted) {
        if (res['ok'] == true) {
          _snack('Documento guardado en tu expediente');
          setState(() { _archivo = null; _nombreArchivo = null; });
          _nombreCtrl.clear();
          await _cargar();
        } else { _snack(res['message'] ?? 'Error', error: true); }
      }
    } catch (_) {}
    if (mounted) setState(() => _subiendo = false);
  }

  Future<void> _eliminar(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Eliminar documento', style: AppTextStyles.heading3),
        content: Text('¿Eliminar "$nombre"?', style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.statusRejected))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.eliminarDocumento(id);
      await _cargar();
    }
  }

  void _snack(String m, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m),
      backgroundColor: error ? AppColors.statusRejected : AppColors.statusAccepted));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(
      onRefresh: _cargar, color: AppColors.primary, backgroundColor: AppColors.darkCard,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Subir documento
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Subir documento', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text('Guarda aquí tus documentos escolares. El administrador puede verlos.',
                style: AppTextStyles.bodySecondary),
              const SizedBox(height: 16),
              AppTextField(label: 'Nombre del documento', controller: _nombreCtrl,
                hint: 'Ej: Carta de aceptación, CURP, Acta de nacimiento...'),
              const SizedBox(height: 14),
              _PickerArchivo(archivo: _archivo, nombre: _nombreArchivo,
                extensiones: null, onTap: _selArchivo),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Guardar documento', loading: _subiendo,
                onPressed: _archivo != null ? _subir : null),
            ]),
          ),
          const SizedBox(height: 20),
          // Lista de documentos
          if (_lista.isEmpty)
            const EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Expediente vacío',
              subtitle: 'Sube tus documentos para tenerlos siempre disponibles.',
            )
          else ...[
            Text('MIS DOCUMENTOS', style: AppTextStyles.label),
            const SizedBox(height: 12),
            ..._lista.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder)),
                child: Row(children: [
                  Container(width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Icon(Icons.insert_drive_file_rounded,
                      color: AppColors.accent, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['nombre']?.toString() ?? '', style: AppTextStyles.body,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_fecha(d['fecha_subida']?.toString() ?? ''), style: AppTextStyles.caption),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.statusRejected, size: 20),
                    onPressed: () => _eliminar(d['id_documento'], d['nombre']?.toString() ?? ''),
                  ),
                ]),
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _fecha(String f) {
    try { final d = DateTime.parse(f); return '${d.day}/${d.month}/${d.year}'; }
    catch (_) { return f; }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════════════════

class _AntepStatusCard extends StatelessWidget {
  final Map<String, dynamic> antep;
  const _AntepStatusCard({required this.antep});

  @override
  Widget build(BuildContext context) {
    final estado = antep['estado']?.toString() ?? 'pendiente';
    final comentario = antep['comentario_admin']?.toString();
    Color border;
    switch (estado) {
      case 'aprobado': border = AppColors.statusAccepted; break;
      case 'rechazado': border = AppColors.statusRejected; break;
      case 'con_observaciones': border = AppColors.statusPending; break;
      default: border = AppColors.darkBorder;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: border.withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Anteproyecto actual', style: AppTextStyles.label),
            const SizedBox(height: 2),
            Text(antep['titulo']?.toString() ?? '', style: AppTextStyles.heading3),
          ])),
          _AntepChip(estado: estado),
        ]),
        if (comentario != null && comentario.isNotEmpty) ...[
          const SizedBox(height: 10), const Divider(), const SizedBox(height: 6),
          Text('Comentarios:', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(comentario, style: AppTextStyles.bodySecondary),
        ],
      ]),
    );
  }
}

class _AntepChip extends StatelessWidget {
  final String estado;
  const _AntepChip({required this.estado});

  Color get _color {
    switch (estado) {
      case 'aprobado': return AppColors.statusAccepted;
      case 'rechazado': return AppColors.statusRejected;
      case 'con_observaciones': return AppColors.statusPending;
      default: return AppColors.statusPartial;
    }
  }

  String get _label {
    switch (estado) {
      case 'aprobado': return 'Aprobado';
      case 'rechazado': return 'Rechazado';
      case 'con_observaciones': return 'Con observaciones';
      default: return 'En revisión';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20), border: Border.all(color: _color.withOpacity(0.4))),
    child: Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
  );
}

class _EstadoPeriodoChip extends StatelessWidget {
  final String estado;
  const _EstadoPeriodoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color; String label;
    switch (estado) {
      case 'abierto':       color = AppColors.statusAccepted; label = 'Abierto'; break;
      case 'proximo':       color = AppColors.statusPending;  label = 'Próximamente'; break;
      case 'cerrado':       color = AppColors.statusRejected; label = 'Cerrado'; break;
      default:              color = AppColors.textSecondary;  label = 'No habilitado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EstadoReporteChip extends StatelessWidget {
  final String estado;
  const _EstadoReporteChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color; String label;
    switch (estado) {
      case 'revisado':          color = AppColors.statusAccepted; label = 'Revisado'; break;
      case 'con_observaciones': color = AppColors.statusPending;  label = 'Con obs.'; break;
      default:                  color = AppColors.statusPartial;  label = 'Enviado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DropdownPost extends StatelessWidget {
  final List<dynamic> postulaciones;
  final int? value;
  final ValueChanged<int?> onChanged;
  const _DropdownPost({required this.postulaciones, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkBorder)),
    child: DropdownButton<int>(
      value: value, isExpanded: true, dropdownColor: AppColors.darkCard,
      underline: const SizedBox.shrink(), style: AppTextStyles.body,
      items: postulaciones.map<DropdownMenuItem<int>>((p) => DropdownMenuItem(
        value: p['id_postulacion'] as int,
        child: Text(p['proyecto']?.toString() ?? ''))).toList(),
      onChanged: onChanged,
    ),
  );
}

class _PickerArchivo extends StatelessWidget {
  final File? archivo;
  final String? nombre;
  final List<String>? extensiones;
  final VoidCallback onTap;
  const _PickerArchivo({this.archivo, this.nombre, this.extensiones, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hint = extensiones != null
      ? extensiones!.map((e) => e.toUpperCase()).join(' / ')
      : 'Cualquier archivo';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkBg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: archivo != null ? AppColors.primary : AppColors.darkBorder)),
        child: Column(children: [
          Icon(archivo != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
            color: archivo != null ? AppColors.primary : AppColors.textSecondary, size: 28),
          const SizedBox(height: 6),
          Text(nombre ?? 'Toca para seleccionar ($hint)',
            style: AppTextStyles.bodySecondary.copyWith(
              color: archivo != null ? AppColors.primary : AppColors.textSecondary),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}