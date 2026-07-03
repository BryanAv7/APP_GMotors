import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ruta.dart';
import '../services/API_route_service.dart';
import 'NavegarRutaScreen.dart';

class VerRutaScreen extends StatefulWidget {
  final Ruta ruta;

  const VerRutaScreen({super.key, required this.ruta});

  @override
  State<VerRutaScreen> createState() => _VerRutaScreenState();
}

class _VerRutaScreenState extends State<VerRutaScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRuta();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarRuta() async {
    setState(() => _cargando = true);

    try {
      // Obtener las coordenadas origen y destino
      LatLng origen = LatLng(widget.ruta.origenLat!, widget.ruta.origenLng!);
      LatLng destino =
      LatLng(widget.ruta.destinoLat!, widget.ruta.destinoLng!);

      // Calcular la ruta para obtener los puntos de la polilínea
      final resultado = await RouteService.calcularRuta(
        origen: origen,
        destino: destino,
      );

      if (resultado != null && resultado['success'] == true) {
        setState(() {
          _polylinePoints = resultado['polyline'];
          _cargando = false;
        });

        // Mover el mapa al origen
        _mapController.move(origen, 14.0);
      } else {
        setState(() => _cargando = false);
      }
    } catch (e) {
      print('Error al cargar ruta: $e');
      setState(() => _cargando = false);
    }
  }

  void _iniciarNavegacion() {
    if (_polylinePoints.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavegarRutaScreen(
          ruta: widget.ruta,
          polylineInicial: _polylinePoints,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng origen = LatLng(widget.ruta.origenLat!, widget.ruta.origenLng!);
    LatLng destino = LatLng(widget.ruta.destinoLat!, widget.ruta.destinoLng!);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: Text(
          widget.ruta.nombreRuta ?? 'Sin nombre',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      )
          : Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-2.9001, -79.0059),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.motos_app',
              ),
              // Polilínea de la ruta
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      color: const Color(0xFFFFD700),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // Marcadores
              MarkerLayer(
                markers: [
                  // Marcador origen (verde)
                  Marker(
                    point: origen,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  // Marcador destino (rojo)
                  Marker(
                    point: destino,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Panel de información
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ruta.nombreRuta ?? 'Sin nombre',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.ruta.descripcion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.ruta.descripcion!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.straighten,
                              color: Color(0xFFFFD700)),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.ruta.distanciaKm?.toStringAsFixed(2) ?? 0} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.schedule,
                              color: Color(0xFFFFD700)),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.ruta.duracionMinutos ?? 0} min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botón iniciar navegación
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                _polylinePoints.isEmpty ? null : _iniciarNavegacion,
                icon: const Icon(Icons.navigation, color: Colors.black),
                label: const Text(
                  'Iniciar Navegación',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}