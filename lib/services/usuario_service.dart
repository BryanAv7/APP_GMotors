import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api.dart';
import '../models/usuario.dart';
import '../utils/token_manager.dart';

class UsuarioService {

  static Future<bool> updateUsuario(Usuario usuario) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final url = Uri.parse('$baseUrl/usuarios/${usuario.idUsuario}');
      final Map<String, dynamic> body = {};
      if (usuario.nombreCompleto != null) body['nombre_completo'] = usuario.nombreCompleto;
      if (usuario.nombreUsuario != null) body['nombre_usuario'] = usuario.nombreUsuario;
      if (usuario.descripcion != null) body['descripcion'] = usuario.descripcion;
      if (usuario.pais != null) body['pais'] = usuario.pais;
      if (usuario.ciudad != null) body['ciudad'] = usuario.ciudad;
      if (usuario.cedula != null) body['cedula'] = usuario.cedula;
      if (usuario.direccion != null) body['direccion'] = usuario.direccion;
      if (usuario.telefono != null) body['telefono'] = usuario.telefono;
      if (usuario.rutaImagen != null) body['rutaimagen'] = usuario.rutaImagen;

      final token = await TokenManager.getToken();
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en updateUsuario: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  static Future<Usuario?> updateUsuarioAndGet(Usuario usuario) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final url = Uri.parse('$baseUrl/usuarios/${usuario.idUsuario}');
      final token = await TokenManager.getToken();
      if (token == null) return null;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        final usuarioBD = Usuario.fromJson(jsonDecode(response.body));
        await TokenManager.saveUserJson(usuarioBD.toJson());
        return usuarioBD;
      }

      return null;
    } catch (e) {
      print('Error en updateUsuarioAndGet: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =========================
  // Cargar la imagen
  // =========================
  static Future<UploadResponse?> uploadImage(File file) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) throw Exception("IP del servidor no configurada");

      final url = Uri.parse('$baseUrl/usuarios/upload');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final token = await TokenManager.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return UploadResponse(
          url: jsonResponse['url'] ?? '',
          mensaje: jsonResponse['mensaje'] ?? 'Imagen subida',
        );
      } else {
        try {
          final Map<String, dynamic> errorResponse = jsonDecode(responseBody);
          throw Exception('Error: ${errorResponse['mensaje'] ?? 'Error desconocido'}');
        } catch (_) {
          throw Exception('Error al subir imagen: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error en uploadImage: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =====================================================
  // OBTENER TODOS LOS USUARIOS (GET /api/usuarios)
  // =====================================================
  static Future<List<Usuario>> obtenerUsuarios() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      if (baseUrl.isEmpty) throw Exception("IP del servidor no configurada");

      final uri = Uri.parse('$baseUrl/usuarios');
      final token = await TokenManager.getToken();
      if (token == null) throw Exception("No hay token de autenticación");

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("[UsuariosService] OBTENER USUARIOS → ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Usuario.fromJson(json)).toList();
      } else {
        final errorMsg = _extraerMensajeError(response);
        throw Exception('Error al cargar usuarios: ${response.statusCode} - $errorMsg');
      }
    } catch (e) {
      print('Error en obtenerUsuarios: $e');
      throw Exception(
          'No se pudo conectar con el servidor o Supabase está apagado. '
              'Por favor contacte con un administrador. Detalle: $e'
      );
    }
  }

  // =====================================================
  // UTILIDAD: Extraer mensaje de error del cuerpo o usar razón estándar
  // =====================================================
  static String _extraerMensajeError(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['mensaje'] ??
          body['error'] ??
          body['message'] ??
          response.reasonPhrase ??
          'Error desconocido';
    } catch (_) {
      return response.reasonPhrase ?? 'Error desconocido';
    }
  }
}

// Clase para encapsular la respuesta de upload
class UploadResponse {
  final String url;
  final String mensaje;

  UploadResponse({
    required this.url,
    required this.mensaje,
  });

  @override
  String toString() => 'UploadResponse(url: $url, mensaje: $mensaje)';
}
