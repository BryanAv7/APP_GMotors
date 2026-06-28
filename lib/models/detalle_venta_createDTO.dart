class DetalleVentaCreateDTO {
  final int? idProducto;
  final String? descripcion;
  final int cantidad;
  final double precioUnitario;

  DetalleVentaCreateDTO({
    this.idProducto,
    this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory DetalleVentaCreateDTO.fromJson(Map<String, dynamic> json) {
    return DetalleVentaCreateDTO(
      idProducto: json['idProducto'],
      descripcion: json['descripcion'],
      cantidad: json['cantidad'],
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProducto': idProducto,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
    };
  }
}
