import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/API_route_service.dart';
import '../services/ruta_service.dart';
import '../services/locationservice.dart';
import '../models/ruta.dart';
import '../utils/token_manager.dart';
import 'NavegarRutaScreen.dart';

class CrearRutaPage extends StatefulWidget {
  const CrearRutaPage({super.key});

  @override
  State<CrearRutaPage> createState() => _CrearRutaPageState();
}

class _CrearRutaPageState extends State<CrearRutaPage> {
  final MapController _mapController = MapController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  LatLng? _ubicacionActual;
  LatLng? _origen;
  LatLng? _destino;
  List<LatLng> _polylinePoints = [];

  double? _distanciaKm;
  int? _duracionMinutos;

  bool _calculando = false;
  bool _guardando = false;
  bool _cargandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _solicitarUbicacion();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Solicitar ubicación al entrar
  Future<void> _solicitarUbicacion() async {
    setState(() => _cargandoUbicacion = true);

    final ubicacion = await LocationService.obtenerUbicacionActual();

    setState(() {
      _ubicacionActual = ubicacion;
      _origen = ubicacion;
      _cargandoUbicacion = false;
    });

    if (ubicacion != null) {
      _mapController.move(ubicacion, 15.0);
    }
  }

  // Establecer origen como ubicación actual
  void _establecerOrigenActual() {
    if (_ubicacionActual != null) {
      setState(() => _origen = _ubicacionActual);
    }
  }

  void _iniciarNavegacion() {
    if (_origen == null || _destino == null || _polylinePoints.isEmpty) return;

    final rutaTemporal = Ruta(
      origenLat: _origen!.latitude,
      origenLng: _origen!.longitude,
      destinoLat: _destino!.latitude,
      destinoLng: _destino!.longitude,
      distanciaKm: _distanciaKm ?? 0,
      duracionMinutos: _duracionMinutos ?? 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavegarRutaScreen(
          ruta: rutaTemporal,
          polylineInicial: _polylinePoints,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          'Crear Ruta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_distanciaKm != null && _duracionMinutos != null)
            IconButton(
              icon: _guardando
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.save, color: Colors.black),
              onPressed: _guardando ? null : _mostrarDialogoGuardar,
              tooltip: 'Guardar Ruta',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-2.9001, -79.0059),
              initialZoom: 13.0,
              onTap: (tapPosition, point) => _agregarPunto(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.motos_app',
              ),
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
              MarkerLayer(
                markers: [
                  // Marcador ubicación actual
                  if (_ubicacionActual != null)
                    Marker(
                      point: _ubicacionActual!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  // Marcador origen
                  if (_origen != null)
                    Marker(
                      point: _origen!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  // Marcador destino
                  if (_destino != null)
                    Marker(
                      point: _destino!,
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

          // Panel superior
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
                  const Text(
                    'Toca el mapa para marcar:',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _origen == null ? '1. Punto de inicio' : '✓ Origen marcado',
                        style: TextStyle(
                          color: _origen == null ? Colors.white54 : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _destino == null ? '2. Punto de destino' : '✓ Destino marcado',
                        style: TextStyle(
                          color: _destino == null ? Colors.white54 : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_distanciaKm != null && _duracionMinutos != null) ...[
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.straighten, color: Color(0xFFFFD700)),
                            const SizedBox(height: 4),
                            Text(
                              '${_distanciaKm!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.schedule, color: Color(0xFFFFD700)),
                            const SizedBox(height: 4),
                            Text(
                              '$_duracionMinutos min',
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
                ],
              ),
            ),
          ),

          // Botón ubicación actual
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFFD700),
              onPressed: _cargandoUbicacion ? null : _establecerOrigenActual,
              tooltip: 'Usar ubicación actual',
              child: _cargandoUbicacion
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
                  : const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // Botones inferiores
          if (_origen != null && _destino != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _limpiar,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _calculando ? null : _calcularRuta,
                          icon: _calculando
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.route, color: Colors.black),
                          label: Text(
                            _calculando ? 'Calculando...' : 'Calcular Ruta',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_distanciaKm != null && _duracionMinutos != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _iniciarNavegacion,
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
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _agregarPunto(LatLng point) {
    setState(() {
      if (_origen == null) {
        _origen = point;
      } else if (_destino == null) {
        _destino = point;
      } else {
        _origen = point;
        _destino = null;
        _polylinePoints.clear();
        _distanciaKm = null;
        _duracionMinutos = null;
      }
    });
  }

  Future<void> _calcularRuta() async {
    if (_origen == null || _destino == null) return;

    setState(() => _calculando = true);

    final resultado = await RouteService.calcularRuta(
      origen: _origen!,
      destino: _destino!,
    );

    setState(() => _calculando = false);

    if (resultado == null || resultado['success'] != true) {
      return;
    }

    setState(() {
      _polylinePoints = resultado['polyline'];
      _distanciaKm = resultado['distancia_km'];
      _duracionMinutos = resultado['duracion_minutos'];
    });
  }

  void _limpiar() {
    setState(() {
      _origen = null;
      _destino = null;
      _polylinePoints.clear();
      _distanciaKm = null;
      _duracionMinutos = null;
    });
  }

  void _mostrarDialogoGuardar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Guardar Ruta',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nombre de la ruta',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2B2B2B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Descripción (opcional)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2B2B2B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarRuta();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarRuta() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => _guardando = true);

    final userMap = await TokenManager.getUserJson();
    if (userMap == null) {
      setState(() => _guardando = false);
      return;
    }

    final idUsuario = userMap['id_usuario'] ?? userMap['idUsuario'];

    final ruta = Ruta(
      idUsuario: idUsuario,
      nombreRuta: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      origenLat: _origen!.latitude,
      origenLng: _origen!.longitude,
      destinoLat: _destino!.latitude,
      destinoLng: _destino!.longitude,
      distanciaKm: _distanciaKm!,
      duracionMinutos: _duracionMinutos!,
    );

    final resultado = await RutaService.crearRuta(ruta);

    setState(() => _guardando = false);

    if (resultado != null && resultado['success'] == true) {
      Navigator.pop(context, true);
    }
  }
}