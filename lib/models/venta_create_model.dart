import 'detalle_venta_createDTO.dart';

class VentaCreateModel {
  final String nombre;
  final String cedula;
  final String? direccion;
  final String? telefono;
  final String? correo;

  final int idUsuarioVendedor;
  final String? observaciones;

  final List<DetalleVentaCreateDTO> detalles;

  VentaCreateModel({
    required this.nombre,
    required this.cedula,
    this.direccion,
    this.telefono,
    this.correo,
    required this.idUsuarioVendedor,
    this.observaciones,
    required this.detalles,
  });

  factory VentaCreateModel.fromJson(Map<String, dynamic> json) {
    return VentaCreateModel(
      nombre: json['nombre'],
      cedula: json['cedula'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      correo: json['correo'],
      idUsuarioVendedor: json['idUsuarioVendedor'],
      observaciones: json['observaciones'],
      detalles: (json['detalles'] as List)
          .map((e) => DetalleVentaCreateDTO.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'cedula': cedula,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'idUsuarioVendedor': idUsuarioVendedor,
      'observaciones': observaciones,
      'detalles': detalles.map((e) => e.toJson()).toList(),
    };
  }
}