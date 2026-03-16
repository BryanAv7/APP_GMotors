class Categoria {
  final int idCategoria;
  final String nombre;

  Categoria({
    required this.idCategoria,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'],
      nombre: json['nombre'],
    );
  }
}