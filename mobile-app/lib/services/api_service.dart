import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Cambiar esta URL por la IP real del servidor donde corre el backend ──
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // En dispositivo físico usa la IP local: ej. 'http://192.168.1.X:3000/api'

  // ── Token management ─────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUsuario(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario));
  }

  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('usuario');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // ── Headers ──────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final res = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> registro({
    required String nombre,
    required String correo,
    required String contrasena,
    required String matricula,
    required String carrera,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/usuarios/registro'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'nombre': nombre, 'correo': correo, 'contrasena': contrasena,
        'matricula': matricula, 'carrera': carrera,
      }),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    final res = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Proyectos ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProyectos({String? carrera}) async {
    var url = '$baseUrl/proyectos';
    if (carrera != null) url += '?carrera=$carrera';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getProyecto(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/proyectos/$id'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Postulaciones ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> postular(int idProyecto) async {
    final res = await http.post(
      Uri.parse('$baseUrl/postulaciones'),
      headers: await _headers(),
      body: jsonEncode({'id_proyecto': idProyecto}),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisPostulaciones() async {
    final res = await http.get(
      Uri.parse('$baseUrl/postulaciones/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Anteproyecto ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> subirAnteproyecto({
    required File archivo,
    required String titulo,
    String? descripcion,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/anteproyectos'),
    );
    request.headers['Authorization'] = 'Bearer \$token';
    request.fields['titulo'] = titulo;
    if (descripcion != null) request.fields['descripcion'] = descripcion;
    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMiAnteproyecto() async {
    final res = await http.get(
      Uri.parse('$baseUrl/anteproyectos/mi'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Reportes ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> subirReporte({
    required int numeroReporte,
    required String periodoCubre,
    required File archivo,
    String? comentarios,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/reportes'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['numero_reporte'] = numeroReporte.toString();
    request.fields['periodo_cubre'] = periodoCubre;
    if (comentarios != null) request.fields['comentarios_adicionales'] = comentarios;
    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisReportes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Evaluaciones ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMisEvaluaciones() async {
    final res = await http.get(
      Uri.parse('$baseUrl/evaluaciones/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Notificaciones ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNotificaciones() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notificaciones'),
      headers: await _headers(),
    );
    return _parse(res);
  }


  // ── Evidencias (alumno → asesor, siempre abierto) ────────────
  static Future<Map<String, dynamic>> subirEvidencia({
    required File archivo,
    String? descripcion,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('\$baseUrl/evidencias'));
    request.headers['Authorization'] = 'Bearer \$token';
    if (descripcion != null) request.fields['descripcion'] = descripcion;
    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisEvidencias() async {
    final res = await http.get(Uri.parse('\$baseUrl/evidencias/mis'), headers: await _headers());
    return _parse(res);
  }

  // ── Documentos (expediente digital) ──────────────────────────
  static Future<Map<String, dynamic>> subirDocumento({
    required File archivo,
    required String nombre,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('\$baseUrl/documentos'));
    request.headers['Authorization'] = 'Bearer \$token';
    request.fields['nombre'] = nombre;
    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisDocumentos() async {
    final res = await http.get(Uri.parse('\$baseUrl/documentos/mis'), headers: await _headers());
    return _parse(res);
  }

  static Future<Map<String, dynamic>> eliminarDocumento(int id) async {
    final res = await http.delete(Uri.parse('\$baseUrl/documentos/\$id'), headers: await _headers());
    return _parse(res);
  }

  // ── Periodos de reporte ───────────────────────────────────────
  static Future<Map<String, dynamic>> getPeriodos() async {
    final res = await http.get(Uri.parse('\$baseUrl/reportes/periodos'), headers: await _headers());
    return _parse(res);
  }

  // ── Parser general ────────────────────────────────────────────────────────
  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body;
    } catch (_) {
      return {'ok': false, 'message': 'Error de conexión (${res.statusCode})'};
    }
  }
}