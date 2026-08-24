import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/token_manager.dart';

class CambiarContrasenaService {

  static Future<Map<String, dynamic>> cambiarContrasena({
    required int idUsuario,
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) {
        return {
          'success': false,
          'mensaje': 'No se pudo obtener la URL del servidor'
        };
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'mensaje': 'No hay sesión activa'
        };
      }

      final url = Uri.parse('$baseUrl/usuarios/$idUsuario/cambiarContrasena');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contrasenaActual': contrasenaActual,
          'contrasenaNueva': contrasenaNueva,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'mensaje': data['mensaje'] ?? 'Contraseña actualizada correctamente'
        };
      } else {
        return {
          'success': false,
          'mensaje': data['mensaje'] ?? 'Error al cambiar la contraseña'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'mensaje': 'Error de conexión: No se pudo conectar al servidor'
      };
    }
  }
}