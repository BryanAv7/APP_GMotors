import 'detalle_venta_model.dart';

class VentaListadoModel {
  final int idVenta;
  final DateTime fechaEmision;
  final double costoTotal;
  final String? observaciones;

  final int idClienteRapido;
  final String nombreCliente;
  final String cedulaCliente;
  final String? telefonoCliente;
  final String? correoCliente;
  final String? direccionCliente;

  final int idUsuarioVendedor;

  final List<DetalleVentaModel> detalles;

  VentaListadoModel({
    required this.idVenta,
    required this.fechaEmision,
    required this.costoTotal,
    this.observaciones,
    required this.idClienteRapido,
    required this.nombreCliente,
    required this.cedulaCliente,
    this.telefonoCliente,
    this.correoCliente,
    this.direccionCliente,
    required this.idUsuarioVendedor,
    required this.detalles,
  });

  factory VentaListadoModel.fromJson(Map<String, dynamic> json) {
    return VentaListadoModel(
      idVenta: json['idVenta'],
      fechaEmision: _parseFecha(json['fechaEmision']),
      costoTotal: (json['costoTotal'] as num).toDouble(),
      observaciones: json['observaciones'],
      idClienteRapido: json['idClienteRapido'],
      nombreCliente: json['nombreCliente'],
      cedulaCliente: json['cedulaCliente'] ?? '',
      telefonoCliente: json['telefonoCliente'],
      correoCliente: json['correoCliente'],
      direccionCliente: json['direccionCliente'],
      idUsuarioVendedor: json['idUsuarioVendedor'],
      detalles: (json['detalles'] as List)
          .map((e) => DetalleVentaModel.fromJson(e))
          .toList(),
    );
  }

  static DateTime _parseFecha(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is List) {

      return DateTime(
        value[0] as int, // año
        value[1] as int, // mes
        value[2] as int, // día
      );
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'idVenta': idVenta,
      'fechaEmision': fechaEmision.toIso8601String(),
      'costoTotal': costoTotal,
      'observaciones': observaciones,
      'idClienteRapido': idClienteRapido,
      'nombreCliente': nombreCliente,
      'cedulaCliente': cedulaCliente,
      'telefonoCliente': telefonoCliente,
      'correoCliente': correoCliente,
      'direccionCliente': direccionCliente,
      'idUsuarioVendedor': idUsuarioVendedor,
      'detalles': detalles.map((e) => e.toJson()).toList(),
    };
  }
}