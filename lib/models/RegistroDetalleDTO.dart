class RegistroDetalleDTO {
  final int idRegistro;
  final String fecha;
  final int estado;
  final String? descripcion;

  // CLIENTE
  final int? idCliente;
  final String? nombreCliente;
  final String? cedulaCliente;
  final String? telefonoCliente;
  final String? direccionCliente;
  final String? correoCliente;

  // ENCARGADO
  final int? idEncargado;
  final String? nombreEncargado;

  // MOTO
  final int? idMoto;
  final String? marcaMoto;
  final String? modeloMoto;
  final String? placaMoto;
  final String? rutaImagenMoto;
  final int? kilometraje;

  // TIPO DE MANTENIMIENTO
  final String? tipoMantenimiento;

  // FACTURA
  final int? idFactura;
  final double? costoTotal;

  RegistroDetalleDTO({
    required this.idRegistro,
    required this.fecha,
    required this.estado,
    this.descripcion,
    this.idCliente,
    this.nombreCliente,
    this.cedulaCliente,
    this.telefonoCliente,
    this.direccionCliente,
    this.correoCliente,
    this.idEncargado,
    this.nombreEncargado,
    this.idMoto,
    this.marcaMoto,
    this.modeloMoto,
    this.placaMoto,
    this.rutaImagenMoto,
    this.kilometraje,
    this.tipoMantenimiento,
    this.idFactura,
    this.costoTotal,
  });

  factory RegistroDetalleDTO.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para manejar campos que pueden ser String o List<dynamic>
    String? _parseStringOrList(dynamic value) {
      if (value == null) return null;

      if (value is String) {
        return value.isNotEmpty ? value : null;
      } else if (value is List) {
        // Si es una lista vacía, retorna null
        if (value.isEmpty) return null;
        // Si la lista tiene elementos, intenta convertir el primero a string
        return value.first.toString();
      } else {
        // Para cualquier otro tipo, convertir a string
        return value.toString();
      }
    }

    // Función auxiliar para manejar campos numéricos
    int? _parseIntOrList(dynamic value) {
      if (value == null) return null;

      if (value is int) {
        return value;
      } else if (value is String && value.isNotEmpty) {
        return int.tryParse(value);
      } else if (value is List) {
        if (value.isEmpty) return null;
        if (value.first is int) return value.first;
        if (value.first is String) return int.tryParse(value.first);
        return null;
      } else if (value is double) {
        return value.toInt();
      }
      return null;
    }

    // Función auxiliar para manejar campos double
    double? _parseDoubleOrList(dynamic value) {
      if (value == null) return null;

      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String && value.isNotEmpty) {
        return double.tryParse(value);
      } else if (value is List) {
        if (value.isEmpty) return null;
        if (value.first is double) return value.first;
        if (value.first is int) return (value.first as int).toDouble();
        if (value.first is String) return double.tryParse(value.first);
        return null;
      }
      return null;
    }

    return RegistroDetalleDTO(
      idRegistro: json['idRegistro'] as int? ?? 0,
      fecha: _parseStringOrList(json['fecha']) ?? '',
      estado: _parseIntOrList(json['estado']) ?? 0,
      descripcion: _parseStringOrList(json['descripcion']),
      idCliente: _parseIntOrList(json['idCliente']),
      nombreCliente: _parseStringOrList(json['nombreCliente']),
      cedulaCliente: _parseStringOrList(json['cedulaCliente']),
      telefonoCliente: _parseStringOrList(json['telefonoCliente']),
      direccionCliente: _parseStringOrList(json['direccionCliente']),
      correoCliente: _parseStringOrList(json['correoCliente']),
      idEncargado: _parseIntOrList(json['idEncargado']),
      nombreEncargado: _parseStringOrList(json['nombreEncargado']),
      idMoto: _parseIntOrList(json['idMoto']),
      marcaMoto: _parseStringOrList(json['marcaMoto']),
      modeloMoto: _parseStringOrList(json['modeloMoto']),
      placaMoto: _parseStringOrList(json['placaMoto']),
      rutaImagenMoto: _parseStringOrList(json['rutaImagenMoto']),
      kilometraje: _parseIntOrList(json['kilometraje']),
      tipoMantenimiento: _parseStringOrList(json['tipoMantenimiento']),
      idFactura: _parseIntOrList(json['idFactura']),
      costoTotal: _parseDoubleOrList(json['costoTotal']),
    );
  }
}