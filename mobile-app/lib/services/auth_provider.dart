import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _usuario;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get usuario => _usuario;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _usuario != null;

  Future<void> cargarSesion() async {
    try {
      _usuario = await ApiService.getUsuario();
      print('SESION CARGADA: $_usuario');
      notifyListeners();
    } catch (e, s) {
      print('ERROR CARGAR SESION: $e');
      print(s);
      _usuario = null;
      notifyListeners();
    }
  }

  Future<bool> login(String correo, String contrasena) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(correo, contrasena);

      print('LOGIN PARSED: $res');

      if (res['ok'] == true && res['data'] != null) {
        final data = res['data'];

        final token = data['token'];
        final usuario = data['usuario'];

        if (token == null || usuario == null) {
          _error = 'La respuesta del servidor no incluye token o usuario.';
          _loading = false;
          notifyListeners();
          return false;
        }

        _usuario = Map<String, dynamic>.from(usuario);

        await ApiService.saveToken(token.toString());
        await ApiService.saveUsuario(_usuario!);

        print('TOKEN GUARDADO: $token');
        print('USUARIO GUARDADO: $_usuario');

        _loading = false;
        notifyListeners();
        return true;
      }

      _error = res['message'] ?? 'Error al iniciar sesión';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e, s) {
      print('ERROR LOGIN AUTH_PROVIDER: $e');
      print(s);

      _error = 'Error real: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registro({
    required String nombre,
    required String correo,
    required String contrasena,
    required String matricula,
    required String carrera,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.registro(
        nombre: nombre,
        correo: correo,
        contrasena: contrasena,
        matricula: matricula,
        carrera: carrera,
      );

      print('REGISTRO PARSED: $res');

      _loading = false;
      notifyListeners();

      if (res['ok'] == true) {
        return true;
      }

      _error = res['message'] ?? 'Error al crear cuenta';
      notifyListeners();
      return false;
    } catch (e, s) {
      print('ERROR REGISTRO AUTH_PROVIDER: $e');
      print(s);

      _error = 'Error real: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearSession();
    _usuario = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}