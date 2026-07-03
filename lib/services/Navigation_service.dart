import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

typedef OnPositionUpdate = void Function(
    LatLng posicion, double? rumbo, double velocidadMs);
typedef OnRutaDesviada = void Function(LatLng posicionActual);
typedef OnLlegada = void Function();

class NavigationService {
  StreamSubscription<Position>? _positionSub;

  List<LatLng> ruta;
  final LatLng destino;

  /// Metros de tolerancia
  final double distanciaMaximaDesvio;

  /// Metros de tolerancia  destino
  final double distanciaLlegada;

  final OnPositionUpdate onPositionUpdate;
  final OnRutaDesviada onRutaDesviada;
  final OnLlegada onLlegada;

  bool _llego = false;
  DateTime? _ultimoRecalculo;

  NavigationService({
    required this.ruta,
    required this.destino,
    required this.onPositionUpdate,
    required this.onRutaDesviada,
    required this.onLlegada,
    this.distanciaMaximaDesvio = 40,
    this.distanciaLlegada = 25,
  });

  Future<void> iniciar() async {
    final permiso = await _verificarPermisos();
    if (!permiso) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_procesarPosicion);
  }

  void detener() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Reemplaza la ruta de referencia
  void actualizarRuta(List<LatLng> nuevaRuta) {
    ruta = nuevaRuta;
  }

  Future<bool> _verificarPermisos() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return false;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return false;
    }
    if (permiso == LocationPermission.deniedForever) return false;

    return true;
  }

  void _procesarPosicion(Position pos) {
    final actual = LatLng(pos.latitude, pos.longitude);
    onPositionUpdate(actual, pos.heading, pos.speed);

    if (_llego) return;

    final distDestino = Geolocator.distanceBetween(
      actual.latitude,
      actual.longitude,
      destino.latitude,
      destino.longitude,
    );
    if (distDestino <= distanciaLlegada) {
      _llego = true;
      onLlegada();
      return;
    }

    final distARuta = _distanciaMinimaARuta(actual);
    if (distARuta > distanciaMaximaDesvio) {
      final ahora = DateTime.now();
      // evita disparar recalculos en cadena mientras la API responde
      if (_ultimoRecalculo == null ||
          ahora.difference(_ultimoRecalculo!).inSeconds > 8) {
        _ultimoRecalculo = ahora;
        onRutaDesviada(actual);
      }
    }
  }

  double _distanciaMinimaARuta(LatLng punto) {
    if (ruta.length < 2) return 0;
    double minDist = double.infinity;
    for (int i = 0; i < ruta.length - 1; i++) {
      final d = _distanciaPuntoSegmento(punto, ruta[i], ruta[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  double _distanciaPuntoSegmento(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final px = p.longitude, py = p.latitude;

    final dx = bx - ax;
    final dy = by - ay;

    double t = 0;
    if (dx != 0 || dy != 0) {
      t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
      t = t.clamp(0.0, 1.0);
    }

    final closestLng = ax + t * dx;
    final closestLat = ay + t * dy;

    return Geolocator.distanceBetween(py, px, closestLat, closestLng);
  }

  /// Distancia restante aproximada
  double distanciaRestanteMetros(LatLng actual) {
    if (ruta.isEmpty) return 0;

    int indiceMasCercano = 0;
    double minDist = double.infinity;

    for (int i = 0; i < ruta.length; i++) {
      final d = Geolocator.distanceBetween(
        actual.latitude,
        actual.longitude,
        ruta[i].latitude,
        ruta[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        indiceMasCercano = i;
      }
    }

    double restante = 0;
    for (int i = indiceMasCercano; i < ruta.length - 1; i++) {
      restante += Geolocator.distanceBetween(
        ruta[i].latitude,
        ruta[i].longitude,
        ruta[i + 1].latitude,
        ruta[i + 1].longitude,
      );
    }
    return restante;
  }
}