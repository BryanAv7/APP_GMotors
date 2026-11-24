import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/token_manager.dart';

class ClaveEliminacionService {

  // =========================
  // Actualizar clave
  // =========================
  static Future<void> actualizarClave({
    required BuildContext context,
    required String claveActual,
    required String claveNueva,
    required String confirmarClave,
    required VoidCallback onSuccess,
  }) async {
    // Validaciones previas
    if (claveNueva != confirmarClave) {
      _mostrarAlertaCentral(
        context: context,
        mensaje: 'Las claves no coinciden',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    if (claveActual == claveNueva) {
      _mostrarAlertaCentral(
        context: context,
        mensaje: 'La nueva clave debe ser diferente a la actual',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    if (claveNueva.length < 4) {
      _mostrarAlertaCentral(
        context: context,
        mensaje: 'La clave debe tener al menos 4 caracteres',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: 'No se pudo obtener la URL del servidor',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: 'No hay sesión activa',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }

      final url = Uri.parse('$baseUrl/codigo/actualizar');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'claveActual': claveActual,
          'claveNueva': claveNueva,
        }),
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: 'Error al procesar la respuesta del servidor',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }

      // Manejo de errores
      if (response.statusCode == 200) {
        if (data['success'] == true) {
          _mostrarAlertaCentral(
            context: context,
            mensaje: 'Contraseña Actualizada',
            icono: Icons.check_circle_outline,
            color: Colors.green,
          );
          Future.delayed(const Duration(milliseconds: 300), onSuccess);
          return;
        } else {
          _mostrarAlertaCentral(
            context: context,
            mensaje: data['mensaje'] ?? 'Error al actualizar la clave',
            icono: Icons.error_outline,
            color: Colors.red,
          );
          return;
        }
      } else if (response.statusCode == 400) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: data['mensaje'] ?? 'Datos inválidos',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: '❌ Clave Actual Incorrecta',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      } else if (response.statusCode == 404) {
        _mostrarAlertaCentral(
          context: context,
          mensaje: data['mensaje'] ?? 'Endpoint no encontrado',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      } else {
        _mostrarAlertaCentral(
          context: context,
          mensaje: data['mensaje'] ?? 'Error del servidor (${response.statusCode})',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        return;
      }
    } catch (e) {
      _mostrarAlertaCentral(
        context: context,
        mensaje: 'Error de conexión: No se pudo conectar al servidor',
        icono: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  // =========================
  // Sistema de alertas
  // =========================
  static OverlayEntry? _overlayEntry;

  static void _mostrarAlertaCentral({
    required BuildContext context,
    required String mensaje,
    required IconData icono,
    required Color color,
    Duration duracion = const Duration(seconds: 2),
  }) {
    _removerAlerta();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 70,
        left: 40,
        right: 40,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, color: color, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(duracion, _removerAlerta);
  }

  static void _removerAlerta() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // =========================
  // Validar clave
  // =========================
  static Future<Map<String, dynamic>> validarClave(String clave) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) {
        return {
          'valida': false,
          'mensaje': 'No se pudo obtener la URL del servidor'
        };
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'valida': false,
          'mensaje': 'No hay sesión activa'
        };
      }

      final url = Uri.parse('$baseUrl/codigo/validar');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'clave': clave}),
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return {
          'valida': false,
          'mensaje': 'Error al procesar la respuesta del servidor'
        };
      }

      if (response.statusCode == 200) {
        return {
          'valida': data['valida'] ?? false,
          'mensaje': data['mensaje'] ?? (data['valida'] ? 'Clave válida' : 'Clave incorrecta')
        };
      } else {
        return {
          'valida': false,
          'mensaje': data['mensaje'] ?? 'Error del servidor (${response.statusCode})'
        };
      }
    } catch (e) {
      return {
        'valida': false,
        'mensaje': 'Error de conexión: No se pudo conectar al servidor'
      };
    }
  }
}