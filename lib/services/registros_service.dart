import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/RegistroDetalleDTO.dart';
import '../models/registro_dto.dart';
import '../models/mantenimiento.dart';
import '../utils/token_manager.dart';
import '../models/DetalleFacturaDTO.dart';

/*
REGISTROSSERVICE.DART

Servicio para consumir endpoints de registros (mantenimientos).
*/

class RegistrosService {
  static Future<Uri> _buildUrl(String path) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    if (baseUrl.isEmpty) {
      throw Exception("IP del servidor no configurada");
    }
    return Uri.parse('$baseUrl/registros$path');
  }

  // =====================================================
  // LISTAR REGISTROS (GET /api/registros)
  // =====================================================
  static Future<List<RegistroDTO>> listarRegistros() async {
    try {
      final uri = await _buildUrl('');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => RegistroDTO.fromJson(e)).toList();
      } else {
        throw Exception(
          "Error al cargar registros: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print('Error en listarRegistros: $e');
      rethrow;
    }
  }

  // =====================================================
  // OBTENER DETALLE DE UN REGISTRO (GET /api/registros/{id})
  // =====================================================
  static Future<RegistroDetalleDTO> obtenerDetalle(int idRegistro) async {
    try {
      final uri = await _buildUrl('/$idRegistro');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("[RegistrosService] DETALLE $idRegistro → ${response.statusCode}");

      if (response.statusCode == 200) {
        return RegistroDetalleDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          "Error al cargar detalle del registro $idRegistro: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print('Error en obtenerDetalle: $e');
      rethrow;
    }
  }

  // =====================================================
  // CREAR REGISTRO (POST /api/registros)
  // =====================================================
  static Future<Mantenimiento?> crear(Map<String, dynamic> body) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      if (baseUrl.isEmpty) {
        throw Exception("IP del servidor no configurada");
      }

      final url = Uri.parse('$baseUrl/registros');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        return null;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Mantenimiento.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Error al crear mantenimiento: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en RegistrosService.crear: $e');
      rethrow;
    }
  }

  // =====================================================
  // OBTENER HISTORIAL DE MANTENIMIENTOS POR USUARIO
  // (GET /api/registros/historial/{idCliente})
  // =====================================================
  static Future<List<RegistroDetalleDTO>> obtenerHistorialMantenimientos(
      int idCliente,
      ) async {
    try {
      final uri = await _buildUrl('/historial/$idCliente');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("[RegistrosService] HISTORIAL $idCliente → ${response.statusCode}");

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => RegistroDetalleDTO.fromJson(e)).toList();
      } else {
        throw Exception(
          "Error al cargar historial: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print('Error en obtenerHistorialMantenimientos: $e');
      rethrow;
    }
  }

  // =====================================================
  // OBTENER DETALLES DE FACTURA
  // =====================================================
  static Future<List<DetalleFacturaDTO>> obtenerDetallesFactura(
      int idFactura,
      ) async {
    try {
      final uri = await _buildUrl('/$idFactura/detalles-factura');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => DetalleFacturaDTO.fromJson(e)).toList();
      } else {
        throw Exception(
          "Error al cargar detalles de factura: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print('Error en obtenerDetallesFactura: $e');
      rethrow;
    }
  }

  // =====================================================
// ACTUALIZAR ESTADO (PATCH /api/registros/{id}/estado)
// =====================================================
  static Future<Map<String, dynamic>?> actualizarEstado(
      int idRegistro,
      int nuevoEstado, {
        String? observaciones,
      }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) throw Exception("IP del servidor no configurada");

      String urlString = '$baseUrl/registros/$idRegistro/estado?estado=$nuevoEstado';
      if (observaciones != null && observaciones.isNotEmpty) {
        urlString += '&observaciones=${Uri.encodeComponent(observaciones)}';
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        return null;
      }

      final response = await http.patch(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("[RegistrosService] ACTUALIZAR ESTADO $idRegistro → ${response.statusCode}");

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Error desconocido'};
      }
    } catch (e) {
      print('Error en actualizarEstado: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // =====================================================
  // ACTUALIZAR FACTURA (PUT /api/registros/{idRegistro}/factura)
  // =====================================================
  static Future<Map<String, dynamic>?> actualizarFactura(
      int idRegistro,
      List<Map<String, dynamic>> detalles,
      ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      if (baseUrl.isEmpty) {
        throw Exception("IP del servidor no configurada");
      }

      final url = Uri.parse('$baseUrl/registros/$idRegistro/factura');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        return null;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(detalles),
      );

      print(
        "[RegistrosService] ACTUALIZAR FACTURA $idRegistro → ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Error al actualizar factura: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en actualizarFactura: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUSCAR HISTORIAL POR NOMBRE DE CLIENTE
  // (GET /api/registros/buscar/nombre?nombreCliente=...)
  // =====================================================
  static Future<List<RegistroDetalleDTO>> buscarHistorialPorNombre(
      String nombreCliente,
      ) async {
    try {
      final uri = await _buildUrl(
        '/buscar/nombre?nombreCliente=$nombreCliente',
      );

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print(
        "[RegistrosService] BUSCAR NOMBRE '$nombreCliente' → ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => RegistroDetalleDTO.fromJson(e)).toList();
      } else {
        throw Exception(
          "Error al buscar: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print('Error en buscarHistorialPorNombre: $e');
      rethrow;
    }
  }

  // =====================================================
  //  BUSCAR HISTORIAL POR NÚMERO DE PLACA (TEXTO)
  // =====================================================
  static Future<List<RegistroDetalleDTO>> buscarHistorialPorPlacaTexto(
      String placa,
      ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) {
        throw Exception("IP del servidor no configurada");
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception("No hay token de autenticación");
      }

      // Consultar la moto por placa para obtener el dueño
      final motoUri = Uri.parse('$baseUrl/motos/placa/$placa');

      print("[RegistrosService] BUSCAR PLACA TEXTO '$placa' → $motoUri");

      final motoResponse = await http.get(
        motoUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print(
        "[RegistrosService] MOTO PLACA '$placa' → ${motoResponse.statusCode}",
      );

      if (motoResponse.statusCode == 404) {
        throw Exception('No se encontró ningún vehículo con la placa "$placa"');
      }

      if (motoResponse.statusCode != 200) {
        throw Exception(
          'Error al buscar la placa: ${motoResponse.statusCode} ${motoResponse.reasonPhrase}',
        );
      }

      // Extraer nombre del cliente desde el JSON de la moto
      final motoData = json.decode(motoResponse.body);

      // Intentar obtener el nombre desde el objeto usuario anidado
      final String nombreCliente =
          motoData['usuario']?['nombre_completo'] as String? ?? '';

      if (nombreCliente.isEmpty) {
        throw Exception(
          'El vehículo con placa "$placa" no tiene un dueño registrado',
        );
      }

      print(
        "[RegistrosService] Placa '$placa' → dueño: '$nombreCliente'",
      );

      // búsqueda por nombre para traer el historial
      return buscarHistorialPorNombre(nombreCliente);
    } catch (e) {
      print('Error en buscarHistorialPorPlacaTexto: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUSCAR HISTORIAL POR PLACA CON OCR (imagen)
  // (POST /api/registros/ocr/historial)
  // =====================================================
  static Future<List<RegistroDetalleDTO>> buscarHistorialPorPlacaOCR(
      Uint8List imageBytes,
      ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl/registros/ocr/historial');

      final token = await TokenManager.getToken();
      if (token == null) {
        print('No hay token disponible');
        throw Exception("No hay token de autenticación");
      }

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'placa_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      print("[RegistrosService] BUSCAR OCR PLACA → enviando imagen");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("[RegistrosService] OCR PLACA → ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);

        if (data['success'] == true && data['historial'] != null) {
          final List historialData = data['historial'];
          return historialData
              .map((e) => RegistroDetalleDTO.fromJson(e))
              .toList();
        } else {
          throw Exception(data['mensaje'] ?? "Error desconocido");
        }
      } else {
        throw Exception("Error al buscar: ${response.statusCode}");
      }
    } catch (e) {
      print('Error en buscarHistorialPorPlacaOCR: $e');
      rethrow;
    }
  }
}