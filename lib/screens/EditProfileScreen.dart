import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../utils/token_manager.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Usuario usuario;

  const EditProfileScreen({super.key, required this.usuario});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nombreUsuarioController;
  late TextEditingController nombreCompletoController;
  late TextEditingController descripcionController;
  late TextEditingController cedulaController;
  late TextEditingController direccionController;
  late TextEditingController telefonoController;
  late TextEditingController paisController;
  late TextEditingController ciudadController;
  File? nuevaImagen;
  bool isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nombreUsuarioController =
        TextEditingController(text: widget.usuario.nombreUsuario);
    nombreCompletoController =
        TextEditingController(text: widget.usuario.nombreCompleto);
    descripcionController =
        TextEditingController(text: widget.usuario.descripcion);
    cedulaController = TextEditingController(text: widget.usuario.cedula);
    direccionController = TextEditingController(text: widget.usuario.direccion);
    telefonoController = TextEditingController(text: widget.usuario.telefono);
    paisController = TextEditingController(text: widget.usuario.pais);
    ciudadController = TextEditingController(text: widget.usuario.ciudad);
  }

  @override
  void dispose() {
    nombreUsuarioController.dispose();
    nombreCompletoController.dispose();
    descripcionController.dispose();
    paisController.dispose();
    ciudadController.dispose();
    cedulaController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  Future<void> seleccionarImagen() async {
    final XFile? imagen =
    await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        nuevaImagen = File(imagen.path);
      });
    }
  }

  Future<String?> subirImagen(File file) async {
    setState(() {
      isUploadingImage = true;
    });

    try {
      final response = await UsuarioService.uploadImage(file);

      if (response != null && response.url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.mensaje)),
        );
        return response.url;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir imagen: respuesta vacía'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title:
        const Text('Editar Perfil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar con indicador de carga
            Stack(
              children: [
                GestureDetector(
                  onTap: isUploadingImage ? null : seleccionarImagen,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[850],
                    backgroundImage: nuevaImagen != null
                        ? FileImage(nuevaImagen!)
                        : (widget.usuario.rutaImagen != null &&
                        widget.usuario.rutaImagen!.isNotEmpty
                        ? NetworkImage(widget.usuario.rutaImagen!)
                    as ImageProvider
                        : null),
                    child: (nuevaImagen == null &&
                        (widget.usuario.rutaImagen == null ||
                            widget.usuario.rutaImagen!.isEmpty))
                        ? const Icon(Icons.camera_alt,
                        color: Colors.grey, size: 36)
                        : null,
                  ),
                ),
                // Indicador de carga
                if (isUploadingImage)
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.black45,
                      child: const CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.yellow),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isUploadingImage
                  ? 'Subiendo imagen...'
                  : 'Toca la foto para cambiar',
              style: TextStyle(
                color: isUploadingImage ? Colors.yellow[700] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Información del Usuario",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Nombre Usuario
            TextField(
              controller: nombreUsuarioController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre Usuario',
                hintText: 'Ej.: TheRock07',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Nombre Completo
            TextField(
              controller: nombreCompletoController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                hintText: 'Ej.: Luis López',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Descripción
            TextField(
              controller: descripcionController,
              enabled: !isUploadingImage,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej.: ¡Hola!,Bienvenidos a mi Perfil.',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Datos para Facturas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Cedula
            TextField(
              controller: cedulaController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cédula/RUC',
                hintText: 'Ingrese 10 a 13 dígitos',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Dirección
            TextField(
              controller: direccionController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Dirección',
                hintText: 'Ej.: Av. Loja y Remigio Crespo',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Telefono
            TextField(
              controller: telefonoController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ej.: 0991234567',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Ubicación",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // País
            TextField(
              controller: paisController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'País',
                hintText: 'Ej.: Ecuador',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Ciudad
            TextField(
              controller: ciudadController,
              enabled: !isUploadingImage,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ciudad',
                hintText: 'Ej.: Cuenca',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUploadingImage
                    ? null
                    : () async {

                  final nombreCompleto = nombreCompletoController.text.trim();

                  if (nombreCompleto.split(RegExp(r'\s+')).length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingrese al menos un nombre y un apellido.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  String rutaImagenActualizada =
                      widget.usuario.rutaImagen ?? '';

                  // Si hay imagen nueva, subirla a Supabase
                  if (nuevaImagen != null) {
                    final urlSubida = await subirImagen(nuevaImagen!);
                    if (urlSubida != null) {
                      rutaImagenActualizada = urlSubida;
                    } else {
                      // No continuar si falla el upload
                      return;
                    }
                  }

                  // Crear usuario actualizado
                  final usuarioActualizado = Usuario(
                    idUsuario: widget.usuario.idUsuario,
                    nombreUsuario: nombreUsuarioController.text,
                    nombreCompleto: nombreCompletoController.text.trim(),
                    descripcion: descripcionController.text,
                    pais: paisController.text,
                    ciudad: ciudadController.text,
                    cedula: cedulaController.text,
                    direccion: direccionController.text,
                    telefono: telefonoController.text,
                    rutaImagen: rutaImagenActualizada,
                  );

                  // Actualizar en base de datos
                  final ok = await UsuarioService
                      .updateUsuario(usuarioActualizado);

                  if (ok) {
                    // Guardar en token manager
                    await TokenManager.saveUserJson(
                        usuarioActualizado.toJson());

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pop(context, usuarioActualizado);
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al actualizar perfil'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  disabledBackgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.black),
                label: Text(
                  isUploadingImage ? 'Subiendo...' : 'Guardar Cambios',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}