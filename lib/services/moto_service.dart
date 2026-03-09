import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api.dart';
import '../models/moto.dart';
import '../utils/token_manager.dart';

class MotoService {

  // =========================
  // Crear una nueva moto
  // =========================
  static Future<bool> crearMoto(Moto moto) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final url = Uri.parse('$baseUrl/motos');
      final Map<String, dynamic> body = moto.toJson();

      final token = await TokenManager.getToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error en crearMoto: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Obtener la moto por ID
  // =========================
  static Future<Moto?> obtenerMotoPorId(int id) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/motos/$id');
      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Moto.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error en obtenerMotoPorId: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Listar todas las motos
  // =========================
  static Future<List<Moto>> listarMotos() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final url = Uri.parse('$baseUrl/motos');
      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Moto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error en listarMotos: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Listar motos por usuario
  // =========================
  static Future<List<Moto>> listarMotosPorUsuario(int idUsuario) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final url = Uri.parse('$baseUrl/motos/usuario/$idUsuario');
      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Moto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error en listarMotosPorUsuario: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
// Buscar moto por placa
// =========================
  static Future<Moto?> obtenerMotoPorPlaca(String placa) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/motos/placa/$placa');

      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Moto.fromJson(data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      return null;

    } catch (e) {
      print('Error en obtenerMotoPorPlaca: $e');
      throw Exception(
          'No se pudo conectar con la Base de Datos. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }
  // =========================
  // Buscar dueño por placa usando OCR
  // =========================
  static Future<Map<String, dynamic>?> buscarDuenoPorPlaca(File imageFile) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/motos/ocr/buscar-dueno');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final token = await TokenManager.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(respStr);
        if (data['success'] == true) {
          return {
            'success': true,
            'idUsuario': data['idUsuario'],
            'nombreCompleto': data['nombreCompleto'],
            'idMoto': data['idMoto'],
            'placa': data['placa'],
            'modelo': data['modelo'],
            'nombreMoto': data['nombreMoto'],
            'marca': data['marca'],
          };
        } else {
          return {
            'success': false,
            'mensaje': data['mensaje'] ?? 'No se encontró el vehículo',
            'placa': data['placa'],
          };
        }
      } else if (response.statusCode == 503) {
        throw Exception('Servidor OCR apagado. Contacte con un administrador.');
      }

      return null;
    } catch (e) {
      print('Error en buscarDuenoPorPlaca: $e');
      throw Exception(
          'No se pudo conectar con el servidor OCR. '
              'El servidor puede estar apagado o no disponible. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Actualizar moto
  // =========================
  static Future<Moto?> actualizarMotoAndGet(Moto motoActualizada) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/motos/${motoActualizada.id_moto}');
      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(motoActualizada.toJson()),
      );

      if (response.statusCode == 200) {
        return Moto.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error en actualizarMotoAndGet: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Detectar placa con OCR
  // =========================
  static Future<String?> detectarPlacaOCR(File image) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/motos/ocr/placa');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final token = await TokenManager.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        return data['placa'];
      } else if (response.statusCode == 503) {
        throw Exception('Servidor OCR apagado. Contacte con un administrador.');
      }

      return null;
    } catch (e) {
      print('Error en detectarPlacaOCR: $e');
      throw Exception(
          'No se pudo conectar con el servidor OCR. '
              'El servidor puede estar apagado o no disponible. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Subir imagen de moto
  // =========================
  static Future<String?> uploadMotoImage(File file) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) throw Exception("IP del servidor no configurada");

      final url = Uri.parse('$baseUrl/motos/upload');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final token = await TokenManager.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        final String? urlImagen = jsonResponse['url'];
        if (urlImagen != null && urlImagen.isNotEmpty) return urlImagen;
        throw Exception('URL vacía en la respuesta');
      } else {
        try {
          final Map<String, dynamic> errorResponse = jsonDecode(responseBody);
          throw Exception('Error: ${errorResponse['mensaje'] ?? 'Error desconocido'}');
        } catch (_) {
          throw Exception('Error al subir imagen: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error en uploadMotoImage: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }
}
