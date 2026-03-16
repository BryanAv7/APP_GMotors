import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoria.dart';
import '../config/api.dart';
import '../utils/token_manager.dart';

class CategoriaService {

  static Future<List<Categoria>> listarCategorias() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) {
        throw Exception("IP del servidor no configurada");
      }

      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception("No hay token de autenticación");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categorias'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => Categoria.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error en CategoriaService.listarCategorias: $e');
      return [];
    }
  }
}