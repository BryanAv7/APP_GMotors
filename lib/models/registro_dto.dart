//Visualización de registro
class RegistroDTO {
  final int idRegistro;
  final String fecha;
  final String descripcion;
  final int estado;
  final String nombreCliente;
  final String placaMoto;
  final String marcaMoto;
  final String modeloMoto;
  final String rutaImagenMoto;

  RegistroDTO({
    required this.idRegistro,
    required this.fecha,
    required this.descripcion,
    required this.estado,
    required this.nombreCliente,
    required this.placaMoto,
    required this.marcaMoto,
    required this.modeloMoto,
    required this.rutaImagenMoto,
  });

  factory RegistroDTO.fromJson(Map<String, dynamic> json) {
    return RegistroDTO(
      idRegistro: json['idRegistro'] ?? 0,
      fecha: _convertToString(json['fecha']),
      descripcion: _convertToString(json['descripcion']),
      estado: json['estado'] ?? 0,
      nombreCliente: _convertToString(json['nombreCliente']),
      placaMoto: _convertToString(json['placaMoto']),
      marcaMoto: _convertToString(json['marcaMoto']),
      modeloMoto: _convertToString(json['modeloMoto']),
      rutaImagenMoto: _convertToString(json['rutaImagenMoto']),
    );
  }

  // Método auxiliar para convertir cualquier tipo a String de forma segura
  static String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      // Si es una lista, tomar el primer elemento o unir con comas
      if (value.isEmpty) return '';
      if (value.length == 1) return value[0].toString();
      return value.join(', ');
    }
    return value.toString();
  }
}