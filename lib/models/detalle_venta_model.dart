class DetalleVentaModel {
  final int idDetalleVenta;
  final int? idProducto;
  final String? descripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVentaModel({
    required this.idDetalleVenta,
    this.idProducto,
    this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    return DetalleVentaModel(
      idDetalleVenta: json['idDetalleVenta'],
      idProducto: json['idProducto'],
      descripcion: json['descripcion'],
      cantidad: json['cantidad'],
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idDetalleVenta': idDetalleVenta,
      'idProducto': idProducto,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}