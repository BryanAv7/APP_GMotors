import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/token_manager.dart';

class QuickAccountResponse {
  final bool success;
  final int? usuarioId;
  final String? nombre;
  final String? email;
  final String? nombreUsuario;
  final String? placa;
  final String? contrasena;
  final String? mensaje;
  final String? error;

  QuickAccountResponse({
    required this.success,
    this.usuarioId,
    this.nombre,
    this.email,
    this.nombreUsuario,
    this.placa,
    this.contrasena,
    this.mensaje,
    this.error,
  });

  factory QuickAccountResponse.fromJson(Map<String, dynamic> json) {
    return QuickAccountResponse(
      success: json['success'] ?? false,
      usuarioId: json['usuarioId'],
      nombre: json['nombre'],
      email: json['email'],
      nombreUsuario: json['nombreUsuario'],
      placa: json['placa'],
      contrasena: json['contrasena'],
      mensaje: json['mensaje'],
      error: json['error'],
    );
  }

  factory QuickAccountResponse.error(String errorMsg) {
    return QuickAccountResponse(
      success: false,
      error: errorMsg,
    );
  }
}

class QuickAccountService {
  // ===================================
  // CREAR CUENTA RÁPIDA
  // ===================================
  static Future<QuickAccountResponse> crearCuentaRapida({
    required String nombreCompleto,
    required String placa,
    String? modeloMoto,
    String? cedula,
    String? direccion,
    String? telefono,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      if (baseUrl.isEmpty) {
        return QuickAccountResponse.error("IP del servidor no configurada");
      }

      final token = await TokenManager.getToken();

      if (token == null || token.isEmpty) {
        return QuickAccountResponse.error("No hay sesión activa. Inicia sesión nuevamente.");
      }

      final url = Uri.parse('$baseUrl/quick-accounts/create');

      final body = {
        'nombre_completo': nombreCompleto.trim(),
        'placa': placa.trim().toUpperCase(),
        if (modeloMoto != null && modeloMoto.trim().isNotEmpty)
          'modelo_moto': modeloMoto.trim(),
        if (cedula != null && cedula.trim().isNotEmpty)
          'cedula': cedula.trim(),
        if (direccion != null && direccion.trim().isNotEmpty)
          'direccion': direccion.trim(),
        if (telefono != null && telefono.trim().isNotEmpty)
          'telefono': telefono.trim(),
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      // Manejar respuesta vacía
      if (response.body.isEmpty) {
        if (response.statusCode == 403) {
          return QuickAccountResponse.error("No tienes permisos para esta acción (403)");
        } else if (response.statusCode == 401) {
          return QuickAccountResponse.error("Sesión expirada, inicia sesión de nuevo (401)");
        } else {
          return QuickAccountResponse.error("Error ${response.statusCode}: Respuesta vacía");
        }
      }

      // Parsear respuesta JSON
      try {
        final jsonData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return QuickAccountResponse.fromJson(jsonData);
        } else {
          final errorMsg = jsonData['error'] ?? 'Error al crear cuenta rápida';
          return QuickAccountResponse.error(errorMsg);
        }
      } catch (e) {
        return QuickAccountResponse.error('Error al procesar respuesta del servidor');
      }
    } catch (e) {
      return QuickAccountResponse.error('Error de conexión: $e');
    }
  }

  // ===================================
  // VALIDAR DATOS
  // ===================================
  static String? validarNombre(String nombre) {
    if (nombre.isEmpty) {
      return "El nombre es obligatorio";
    }
    if (nombre.length < 3) {
      return "El nombre debe tener al menos 3 caracteres";
    }
    return null;
  }

  static String? validarPlaca(String placa) {
    if (placa.isEmpty) {
      return "La placa es obligatoria";
    }
    if (placa.length < 6) {
      return "La placa debe tener al menos 6 caracteres";
    }
    return null;
  }
}