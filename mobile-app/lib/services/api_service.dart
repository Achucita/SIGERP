import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Cambiar esta URL por la IP real del servidor donde corre el backend ──
  static const String baseUrl = 'http://13.59.60.97/api';
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

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ── Usuario en sesión (SharedPreferences) ─────────────────────────────────
  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUsuario(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(usuario));
  }

  /// Limpia token + datos de usuario guardados (equivale al antiguo clearToken).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _authOnlyHeaders() async {
    final token = await getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'ok': false, 'message': 'Respuesta inválida del servidor'};
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String correo, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': password}),
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'matricula': matricula,
        'carrera': carrera,
        'rol': 'alumno',
      }),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    final res = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: await _headers(),
    );
  print('GET PROYECTOS STATUS: ${res.statusCode})');
  print('GET PROYECTOS BODY: ${res.body})');

    return _parse(res);
  }

  // ── Proyectos ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProyectos() async {
    final res = await http.get(
      Uri.parse('$baseUrl/proyectos?estado=publicado'),
      headers: await _headers(),
    );
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
  static Future<Map<String, dynamic>> postular(
    int idProyecto, {
    File? cvFile,
  }) async {
    final token = await getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/postulaciones'),
    )
      ..headers.addAll(headers)
      ..fields['id_proyecto'] = idProyecto.toString();

    if (cvFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cv', cvFile.path),
      );
    }

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
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
    String? asesoresPropuestos,
  }) async {
    final token   = await getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/anteproyectos'),
    )
      ..headers.addAll(headers)
      ..fields['titulo'] = titulo;

    if (descripcion != null) request.fields['descripcion'] = descripcion;
    if (asesoresPropuestos != null) request.fields['asesores_propuestos'] = asesoresPropuestos;

    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisAnteproyectos() async {
    final res = await http.get(
      Uri.parse('$baseUrl/anteproyectos/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  /// Devuelve el anteproyecto más reciente del alumno (o {'ok': false} si no tiene).
  static Future<Map<String, dynamic>> getMiAnteproyecto() async {
    final res = await http.get(
      Uri.parse('$baseUrl/anteproyectos/mis'),
      headers: await _headers(),
    );
    final parsed = _parse(res);
    if (parsed['ok'] == true) {
      final data = parsed['data'];
      if (data is List && data.isNotEmpty) {
        return {'ok': true, 'data': data.first};
      }
      if (data is Map<String, dynamic>) {
        return {'ok': true, 'data': data};
      }
      return {'ok': false, 'message': 'Sin anteproyecto'};
    }
    return parsed;
  }

  // ── Periodos de reporte ────────────────────────────────────────────────────
  /// Obtiene los periodos de reporte configurados por el administrador.
  static Future<Map<String, dynamic>> getPeriodos() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/periodos'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Reportes ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> subirReporte({
    required File archivo,
    required String titulo,
    required int numeroReporte,
    String? periodoInicio,
    String? periodoFin,
    String? descripcion,
    // Parámetro 'tipo' mantenido por compatibilidad con llamadas anteriores
    String tipo = 'parcial',
  }) async {
    final token   = await getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reportes'),
    )
      ..headers.addAll(headers)
      ..fields['titulo']          = titulo
      ..fields['numero_reporte']  = numeroReporte.toString()
      ..fields['tipo']            = tipo;

    if (periodoInicio != null) request.fields['periodo_inicio'] = periodoInicio;
    if (periodoFin    != null) request.fields['periodo_fin']    = periodoFin;
    if (descripcion   != null) request.fields['descripcion']    = descripcion;

    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisReportes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Evidencias ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> subirEvidencia({
    required File archivo,
    String? titulo,
    String? descripcion,
  }) async {
    final token   = await getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/evidencias'),
    )
      ..headers.addAll(headers);

    if (titulo      != null) request.fields['titulo']       = titulo;
    if (descripcion != null) request.fields['descripcion']  = descripcion;

    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  /// Devuelve las evidencias enviadas por el alumno.
  static Future<Map<String, dynamic>> getMisEvidencias() async {
    final res = await http.get(
      Uri.parse('$baseUrl/evidencias/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── Documentos (expediente digital) ───────────────────────────────────────
  /// Sube un documento al expediente del alumno.
  static Future<Map<String, dynamic>> subirDocumento({
    required File archivo,
    required String nombre,
    String? descripcion,
  }) async {
    final token   = await getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documentos'),
    )
      ..headers.addAll(headers)
      ..fields['nombre'] = nombre;

    if (descripcion != null) request.fields['descripcion'] = descripcion;

    request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  /// Devuelve los documentos del expediente del alumno.
  static Future<Map<String, dynamic>> getMisDocumentos() async {
    final res = await http.get(
      Uri.parse('$baseUrl/documentos/mis'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  /// Elimina un documento del expediente del alumno.
  static Future<Map<String, dynamic>> eliminarDocumento(int idDocumento) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/documentos/$idDocumento'),
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
}