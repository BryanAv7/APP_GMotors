import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api.dart';
import '../utils/token_manager.dart';

class RouteService {

  // Calcular ruta entre dos puntos
  static Future<Map<String, dynamic>?> calcularRuta({
    required LatLng origen,
    required LatLng destino,
    List<LatLng>? waypoints,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      if (baseUrl.isEmpty) {
        return {
          'success': false,
          'error': 'No hay IP configurada'
        };
      }

      final token = await TokenManager.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'No hay token de autenticación'
        };
      }

      List<List<double>> coordinates = [
        [origen.longitude, origen.latitude],
      ];

      if (waypoints != null) {
        for (var point in waypoints) {
          coordinates.add([point.longitude, point.latitude]);
        }
      }

      coordinates.add([destino.longitude, destino.latitude]);

      //print('📍 Calculando ruta...');
      //print('Origen: ${origen.latitude}, ${origen.longitude}');
      //print('Destino: ${destino.latitude}, ${destino.longitude}');

      final url = Uri.parse("$baseUrl/routes/calcular-ruta");
      //print('📡 URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coordinates': coordinates,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          List<LatLng> polylinePoints = [];
          for (var point in data['polyline']) {
            polylinePoints.add(LatLng(point['lat'], point['lng']));
          }

          return {
            'success': true,
            'distancia_km': data['distancia_km'],
            'duracion_minutos': data['duracion_minutos'],
            'polyline': polylinePoints,
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        print('❌ Error de autenticación: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Sesión expirada. Por favor, inicia sesión nuevamente.'
        };
      } else {
        //print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'Error al calcular ruta: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Error en calcularRuta: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Buscar lugar por nombre
  static Future<Map<String, dynamic>?> buscarLugar(String query) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      if (baseUrl.isEmpty) {
        return {
          'success': false,
          'error': 'No hay IP configurada'
        };
      }

      final token = await TokenManager.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'No hay token de autenticación'
        };
      }

      final url = Uri.parse("$baseUrl/routes/buscar-lugar?query=$query");
      //print('📡 URL búsqueda: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'lugares': data['lugares'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        print('❌ Error de autenticación: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Sesión expirada. Por favor, inicia sesión nuevamente.'
        };
      }
      return {'success': false, 'error': 'Error en búsqueda'};
    } catch (e) {
      print('Error en buscarLugar: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}