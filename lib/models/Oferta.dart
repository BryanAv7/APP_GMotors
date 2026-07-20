class Oferta {
  final int? idOferta;
  final String titulo;
  final String descripcion;
  final int estado;
  final String? imagenUrl;
  final String fechaInicio;
  final String fechaFin;

  Oferta({
    this.idOferta,
    required this.titulo,
    required this.descripcion,
    this.estado = 2,
    this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory Oferta.fromJson(Map<String, dynamic> json) => Oferta(
    idOferta: json['idOferta'],
    titulo: json['titulo'],
    descripcion: json['descripcion'],
    estado: json['estado'] ?? 2,
    imagenUrl: json['imagenUrl'],
    fechaInicio: json['fechaInicio'],
    fechaFin: json['fechaFin'],
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'estado': estado,
    'imagenUrl': imagenUrl,
    'fechaInicio': fechaInicio,
    'fechaFin': fechaFin,
  };
}