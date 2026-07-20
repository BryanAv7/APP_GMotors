import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../models/oferta.dart';
import '../utils/token_manager.dart';

class OfertaService {

  // ── Crear oferta ──
  static Future<Oferta?> crearOferta(Oferta oferta) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/ofertas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(oferta.toJson()),
      );

      //print(' crearOferta STATUS: ${response.statusCode}');
      //print('crearOferta BODY: ${response.body}');

      if (response.statusCode == 201) {
        return Oferta.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error crearOferta: $e');
      return null;
    }
  }

  // ── Activar oferta → dispara notificación a todos ──
  static Future<bool> activarOferta(int idOferta) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final token = await TokenManager.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$baseUrl/ofertas/$idOferta/activar'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error activarOferta: $e');
      return false;
    }
  }

  // ── Subir imagen a Supabase ──
  static Future<String?> subirImagenOferta(File file) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final token = await TokenManager.getToken();
      if (token == null) return null;

      // Reutiliza el mismo endpoint de upload que ya tienes
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/usuarios/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['url'];
      }
      return null;
    } catch (e) {
      print('Error subirImagenOferta: $e');
      return null;
    }
  }

  // ── Listar todas las ofertas ──
  static Future<List<Oferta>> listarOfertas() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/ofertas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Oferta.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error listarOfertas: $e');
      return [];
    }
  }

  // ── Listar todas las ofertas(Activas) ──

  static Future<List<Oferta>> listarOfertasActivas() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final token = await TokenManager.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/ofertas/activas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Oferta.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error listarOfertasActivas: $e');
      return [];
    }
  }

  // Agregar este método en OfertaService
  static Future<void> registrarToken(String fcmToken) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return;

      final token = await TokenManager.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/ofertas/registrar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      print('------Token FCM registrado en backend--------');
    } catch (e) {
      print('Error registrarToken: $e');
    }
  }
}