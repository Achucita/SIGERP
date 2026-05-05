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

  // Cargar sesión guardada al iniciar app
  Future<void> cargarSesion() async {
    _usuario = await ApiService.getUsuario();
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(correo, contrasena);
      if (res['ok'] == true) {
        _usuario = res['data']['usuario'];
        await ApiService.saveToken(res['data']['token']);
        await ApiService.saveUsuario(_usuario!);
        _loading = false; notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Error al iniciar sesión';
        _loading = false; notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Sin conexión al servidor';
      _loading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> registro({
    required String nombre, required String correo,
    required String contrasena, required String matricula, required String carrera,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.registro(
        nombre: nombre, correo: correo, contrasena: contrasena,
        matricula: matricula, carrera: carrera,
      );
      _loading = false; notifyListeners();
      if (res['ok'] == true) return true;
      _error = res['message'] ?? 'Error al crear cuenta';
      return false;
    } catch (e) {
      _error = 'Sin conexión al servidor';
      _loading = false; notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearSession();
    _usuario = null;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
