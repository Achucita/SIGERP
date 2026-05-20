import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://13.59.60.97/api';
  static const Duration timeout = Duration(seconds: 15);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();

    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response res) {
    print('STATUS: ${res.statusCode}');
    print('BODY: ${res.body}');

    try {
      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'ok': false,
        'message': 'Respuesta inesperada del servidor',
        'statusCode': res.statusCode,
      };
    } catch (e) {
      return {
        'ok': false,
        'message': 'Respuesta inválida del servidor',
        'statusCode': res.statusCode,
        'raw': res.body,
      };
    }
  }

  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/usuarios/login');

    print('LOGIN URL: $url');
    print('LOGIN BODY: $correo');

    final res = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'correo': correo,
            'contrasena': password,
          }),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> registro({
    required String nombre,
    required String correo,
    required String contrasena,
    required String matricula,
    required String carrera,
  }) async {
    final url = Uri.parse('$baseUrl/usuarios/registro');

    print('REGISTRO URL: $url');
    print('REGISTRO BODY: $nombre | $correo | $matricula | $carrera');

    final res = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre,
            'correo': correo,
            'contrasena': contrasena,
            'matricula': matricula,
            'carrera': carrera,
          }),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    final url = Uri.parse('$baseUrl/usuarios/perfil');

    print('GET PERFIL URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getProyectos() async {
    final url = Uri.parse('$baseUrl/proyectos?estado=publicado');

    print('GET PROYECTOS URL: $url');
    print('TOKEN ACTUAL: ${await getToken()}');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getProyecto(int id) async {
    final url = Uri.parse('$baseUrl/proyectos/$id');

    print('GET PROYECTO URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> postular(
    int idProyecto, {
    File? cvFile,
  }) async {
    final url = Uri.parse('$baseUrl/postulaciones');

    print('POSTULAR URL: $url');
    print('POSTULAR PROYECTO: $idProyecto');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(await _authHeaders())
      ..fields['id_proyecto'] = idProyecto.toString();

    if (cvFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cv', cvFile.path),
      );
    }

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisPostulaciones() async {
    final url = Uri.parse('$baseUrl/postulaciones/mis');

    print('GET MIS POSTULACIONES URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> subirAnteproyecto({
    required File archivo,
    required String titulo,
    String? descripcion,
    String? asesoresPropuestos,
  }) async {
    final url = Uri.parse('$baseUrl/anteproyectos');

    print('SUBIR ANTEPROYECTO URL: $url');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(await _authHeaders())
      ..fields['titulo'] = titulo;

    if (descripcion != null) {
      request.fields['descripcion'] = descripcion;
    }

    if (asesoresPropuestos != null) {
      request.fields['asesores_propuestos'] = asesoresPropuestos;
    }

    request.files.add(
      await http.MultipartFile.fromPath('archivo', archivo.path),
    );

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisAnteproyectos() async {
    final url = Uri.parse('$baseUrl/anteproyectos/mis');

    print('GET MIS ANTEPROYECTOS URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMiAnteproyecto() async {
    final parsed = await getMisAnteproyectos();

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

  static Future<Map<String, dynamic>> getPeriodos() async {
    final url = Uri.parse('$baseUrl/reportes/periodos');

    print('GET PERIODOS URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> subirReporte({
    required File archivo,
    required String titulo,
    required int numeroReporte,
    String? periodoInicio,
    String? periodoFin,
    String? descripcion,
    String tipo = 'parcial',
  }) async {
    final url = Uri.parse('$baseUrl/reportes');

    print('SUBIR REPORTE URL: $url');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(await _authHeaders())
      ..fields['titulo'] = titulo
      ..fields['numero_reporte'] = numeroReporte.toString()
      ..fields['tipo'] = tipo;

    if (periodoInicio != null) {
      request.fields['periodo_inicio'] = periodoInicio;
    }

    if (periodoFin != null) {
      request.fields['periodo_fin'] = periodoFin;
    }

    if (descripcion != null) {
      request.fields['descripcion'] = descripcion;
    }

    request.files.add(
      await http.MultipartFile.fromPath('archivo', archivo.path),
    );

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisReportes() async {
    final url = Uri.parse('$baseUrl/reportes/mis');

    print('GET MIS REPORTES URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> subirEvidencia({
    required File archivo,
    String? titulo,
    String? descripcion,
  }) async {
    final url = Uri.parse('$baseUrl/evidencias');

    print('SUBIR EVIDENCIA URL: $url');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(await _authHeaders());

    if (titulo != null) {
      request.fields['titulo'] = titulo;
    }

    if (descripcion != null) {
      request.fields['descripcion'] = descripcion;
    }

    request.files.add(
      await http.MultipartFile.fromPath('archivo', archivo.path),
    );

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisEvidencias() async {
    final url = Uri.parse('$baseUrl/evidencias/mis');

    print('GET MIS EVIDENCIAS URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> subirDocumento({
    required File archivo,
    required String nombre,
    String? descripcion,
  }) async {
    final url = Uri.parse('$baseUrl/documentos');

    print('SUBIR DOCUMENTO URL: $url');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(await _authHeaders())
      ..fields['nombre'] = nombre;

    if (descripcion != null) {
      request.fields['descripcion'] = descripcion;
    }

    request.files.add(
      await http.MultipartFile.fromPath('archivo', archivo.path),
    );

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMisDocumentos() async {
    final url = Uri.parse('$baseUrl/documentos/mis');

    print('GET MIS DOCUMENTOS URL: $url');

    final res = await http
        .get(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }

  static Future<Map<String, dynamic>> eliminarDocumento(int idDocumento) async {
    final url = Uri.parse('$baseUrl/documentos/$idDocumento');

    print('DELETE DOCUMENTO URL: $url');

    final res = await http
        .delete(
          url,
          headers: await _headers(),
        )
        .timeout(timeout);

    return _parse(res);
  }
}