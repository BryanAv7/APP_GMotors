import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/venta_create_model.dart';
import '../models/venta_listado_model.dart';
import '../utils/token_manager.dart';

class VentaService {

  // =========================
  // Crear venta
  // =========================
  static Future<VentaListadoModel?> crearVenta(
      VentaCreateModel venta) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/ventas');

      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(venta.toJson()),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final decoded = jsonDecode(response.body);

        return VentaListadoModel.fromJson(decoded);
      }

      throw Exception(response.body);
    } catch (e) {
      print('Error en crearVenta: $e');
      throw Exception('Error creando venta: $e');
    }
  }

  // =========================
  // LISTAR TODAS
  // =========================
  static Future<List<VentaListadoModel>> listarVentas() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final url = Uri.parse('$baseUrl/ventas');

      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print("ERROR STATUS: ${response.statusCode}");
        print("BODY: ${response.body}");
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => VentaListadoModel.fromJson(e))
            .toList();
      }

      if (decoded is Map && decoded['ventas'] is List) {
        return (decoded['ventas'] as List)
            .map((e) => VentaListadoModel.fromJson(e))
            .toList();
      }

      throw Exception("Formato inesperado: ${decoded.runtimeType}");
    } catch (e) {
      print('Error en listarVentas: $e');
      throw Exception('Error listando ventas: $e');
    }
  }

  // =========================
  // Obtener venta por ID
  // =========================
  static Future<VentaListadoModel?> obtenerVenta(int idVenta) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/ventas/$idVenta');

      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return VentaListadoModel.fromJson(decoded);
      }

      return null;
    } catch (e) {
      print('Error en obtenerVenta: $e');
      throw Exception('Error obteniendo venta: $e');
    }
  }

  // =========================
  // HISTORIAL CÉDULA
  // =========================
  static Future<List<VentaListadoModel>> historialPorCedula(
      String cedula) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final url = Uri.parse('$baseUrl/ventas/historial/cedula/$cedula');

      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['ventas'] is List) {
        return (decoded['ventas'] as List)
            .map((e) => VentaListadoModel.fromJson(e))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error historial cedula: $e');
      throw Exception('Error historial cedula');
    }
  }

  // =========================
  // HISTORIAL NOMBRE
  // =========================
  static Future<List<VentaListadoModel>> historialPorNombre(
      String nombre) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final url = Uri.parse('$baseUrl/ventas/historial/nombre/$nombre');

      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['ventas'] is List) {
        return (decoded['ventas'] as List)
            .map((e) => VentaListadoModel.fromJson(e))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error historial nombre: $e');
      throw Exception('Error historial nombre');
    }
  }

  // =========================
  // ELIMINAR
  // =========================
  static Future<bool> eliminarVenta(int idVenta) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final url = Uri.parse('$baseUrl/ventas/$idVenta');

      final token = await TokenManager.getToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      print('Error eliminarVenta: $e');
      return false;
    }
  }
}