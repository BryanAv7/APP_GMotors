import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ruta.dart';
import '../services/API_route_service.dart';
import '../services/navigation_service.dart';

class NavegarRutaScreen extends StatefulWidget {
  final Ruta ruta;
  final List<LatLng> polylineInicial;

  const NavegarRutaScreen({
    super.key,
    required this.ruta,
    required this.polylineInicial,
  });

  @override
  State<NavegarRutaScreen> createState() => _NavegarRutaScreenState();
}

class _NavegarRutaScreenState extends State<NavegarRutaScreen> {
  final MapController _mapController = MapController();
  NavigationService? _navService;

  late List<LatLng> _polyline;
  late LatLng _destino;

  LatLng? _posicionActual;
  double? _rumbo;
  double _distanciaRestanteM = 0;
  bool _recalculando = false;

  @override
  void initState() {
    super.initState();
    _polyline = widget.polylineInicial;
    _destino = LatLng(widget.ruta.destinoLat!, widget.ruta.destinoLng!);
    _distanciaRestanteM = (widget.ruta.distanciaKm ?? 0) * 1000;
    _iniciarNavegacion();
  }

  void _iniciarNavegacion() {
    _navService = NavigationService(
      ruta: _polyline,
      destino: _destino,
      onPositionUpdate: _onPosicion,
      onRutaDesviada: _onDesvio,
      onLlegada: _onLlegada,
    );
    _navService!.iniciar();
  }

  void _onPosicion(LatLng pos, double? rumbo, double velocidad) {
    if (!mounted) return;
    setState(() {
      _posicionActual = pos;
      _rumbo = rumbo;
      _distanciaRestanteM = _navService!.distanciaRestanteMetros(pos);
    });

    // Sigue al usuario en el mapa
    _mapController.move(pos, 17.5);
    // rotacion de mapa
    // _mapController.rotate(-(rumbo ?? 0));
  }

  Future<void> _onDesvio(LatLng posicionActual) async {
    if (_recalculando) return;
    setState(() => _recalculando = true);

    final resultado = await RouteService.calcularRuta(
      origen: posicionActual,
      destino: _destino,
    );

    if (resultado != null && resultado['success'] == true) {
      final nuevaPolyline = resultado['polyline'] as List<LatLng>;
      setState(() => _polyline = nuevaPolyline);
      _navService?.actualizarRuta(nuevaPolyline);
    }

    if (mounted) setState(() => _recalculando = false);
  }

  void _onLlegada() {
    if (!mounted) return;
    _navService?.detener();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('¡Llegaste!',
            style: TextStyle(color: Color(0xFFFFD700))),
        content: const Text('Has llegado a tu destino.',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cierra el diálogo
              Navigator.pop(context); // sale de la navegación
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navService?.detener();
    _mapController.dispose();
    super.dispose();
  }

  String _formatearDistancia(double metros) {
    if (metros >= 1000) return '${(metros / 1000).toStringAsFixed(2)} km';
    return '${metros.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
              _polyline.isNotEmpty ? _polyline.first : _destino,
              initialZoom: 17.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.motos_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polyline,
                    color: const Color(0xFFFFD700),
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_posicionActual != null)
                    Marker(
                      point: _posicionActual!,
                      width: 44,
                      height: 44,
                      child: Transform.rotate(
                        angle: (_rumbo ?? 0) * 3.1415926535 / 180,
                        child: const Icon(Icons.navigation,
                            color: Colors.blueAccent, size: 36),
                      ),
                    ),
                  Marker(
                    point: _destino,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // Panel superior: distancia restante / estado de recalculo
          Positioned(
            top: 30,
            left: 30,
            right: 30,
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Distancia: ${_formatearDistancia(_distanciaRestanteM)}',
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (_recalculando)
                    const Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFFD700)),
                        ),
                        SizedBox(width: 8),
                        Text('Calculando..',
                            style: TextStyle(color: Colors.white30)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                _navService?.detener();
                Navigator.pop(context);
              },
              label: const Text('Terminar navegación',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}