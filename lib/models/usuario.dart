class Usuario {
  final int? idUsuario;
  final String? nombreCompleto;
  final String? nombreUsuario;
  final String? correo;
  final String? descripcion;
  final String? pais;
  final String? ciudad;
  final String? cedula;
  final String? direccion;
  final String? telefono;
  final String? rutaImagen;

  Usuario({
    this.idUsuario,
    this.nombreCompleto,
    this.nombreUsuario,
    this.correo,
    this.descripcion,
    this.pais,
    this.ciudad,
    this.cedula,
    this.direccion,
    this.telefono,
    this.rutaImagen,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    idUsuario: json['id_usuario'],
    nombreCompleto: json['nombre_completo'],
    nombreUsuario: json['nombre_usuario'],
    correo: json['correo'],
    descripcion: json['descripcion'],
    pais: json['pais'],
    ciudad: json['ciudad'],
    cedula: json['cedula'],
    direccion: json['direccion'],
    telefono: json['telefono'],
    rutaImagen: json['ruta_imagen'],
  );

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'nombre_completo': nombreCompleto,
    'nombre_usuario': nombreUsuario,
    'correo': correo,
    'descripcion': descripcion,
    'pais': pais,
    'ciudad': ciudad,
    'cedula': cedula,
    'direccion': direccion,
    'telefono': telefono,
    'rutaimagen': rutaImagen,
  };
}