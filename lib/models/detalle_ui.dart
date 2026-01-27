import 'productos.dart';

class DetalleUI {
  final int? idProducto;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final bool esProducto; // true = inventario, false = concepto manual
  final String? imagenUrl;

  DetalleUI({
    this.idProducto,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.esProducto,
    this.imagenUrl,
  });

  // ⬅️ CAMBIO AQUÍ: Si es concepto manual, NO multiplica
  double get subtotal {
    if (esProducto) {
      return cantidad * precioUnitario; // Productos SÍ multiplican
    } else {
      return precioUnitario; // Conceptos manuales NO multiplican
    }
  }

  // Constructor desde Producto
  factory DetalleUI.fromProducto(Producto producto, int cantidad) {
    return DetalleUI(
      idProducto: producto.idProducto,
      nombre: producto.nombre ?? 'Sin nombre',
      cantidad: cantidad,
      precioUnitario: producto.pvp ?? 0.0,
      esProducto: true,
      imagenUrl: producto.rutaImagenProductos,
    );
  }

  // Constructor para concepto manual
  factory DetalleUI.conceptoManual({
    required String descripcion,
    required int cantidad,
    required double precio,
  }) {
    return DetalleUI(
      idProducto: null,
      nombre: descripcion,
      cantidad: cantidad,
      precioUnitario: precio,
      esProducto: false,
    );
  }

  // Copiar con nueva cantidad
  DetalleUI copyWith({int? cantidad}) {
    return DetalleUI(
      idProducto: idProducto,
      nombre: nombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario,
      esProducto: esProducto,
      imagenUrl: imagenUrl,
    );
  }

  // Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'cantidad': cantidad,
    };

    if (esProducto && idProducto != null) {
      map['idProducto'] = idProducto;
    } else {
      map['descripcion'] = nombre;
      map['precioUnitario'] = precioUnitario;
    }

    return map;
  }

  // 🔧 CORREGIDO: Manejo correcto de idProducto nullable
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetalleUI &&
        runtimeType == other.runtimeType &&
        idProducto == other.idProducto &&
        // Si es concepto manual (idProducto == null), compara también por nombre
        (idProducto != null || nombre == other.nombre);
  }

  @override
  int get hashCode {
    if (idProducto != null) {
      return idProducto.hashCode;
    } else {
      // Para conceptos manuales, usa el nombre como identificador único
      return nombre.hashCode;
    }
  }
}