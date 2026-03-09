import 'dart:io';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/moto.dart';
import '../services/moto_service.dart';
import 'package:image_picker/image_picker.dart';

class ViewMotorcycleScreen extends StatefulWidget {
  final Usuario usuario;
  final Moto moto;

  const ViewMotorcycleScreen({super.key, required this.usuario, required this.moto});

  @override
  State<ViewMotorcycleScreen> createState() => _ViewMotorcycleScreenState();
}

class _ViewMotorcycleScreenState extends State<ViewMotorcycleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController marcaController;
  late TextEditingController nombreMotoController;
  late TextEditingController modeloController;
  late TextEditingController placaController;
  late TextEditingController anioController;
  late TextEditingController kilometrajeController;
  late TextEditingController cilindrajeController;
  late TextEditingController tipoMotoController;

  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nombreMotoController = TextEditingController(text: widget.moto.nombreMoto ?? '');
    marcaController = TextEditingController(text: widget.moto.marca ?? '');
    modeloController = TextEditingController(text: widget.moto.modelo ?? '');
    placaController = TextEditingController(text: widget.moto.placa ?? '');
    anioController = TextEditingController(text: widget.moto.anio?.toString() ?? '');
    kilometrajeController = TextEditingController(text: widget.moto.kilometraje?.toString() ?? '');
    cilindrajeController = TextEditingController(text: widget.moto.cilindraje?.toString() ?? '');
    tipoMotoController = TextEditingController(text: widget.moto.tipoMoto ?? '');
  }

  @override
  void dispose() {
    nombreMotoController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    placaController.dispose();
    anioController.dispose();
    kilometrajeController.dispose();
    cilindrajeController.dispose();
    tipoMotoController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // detectar placa con OCR
  Future<void> abrirCamaraPlaca() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Detectar Placa',
                  style: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.yellow),
                title: const Text('Tomar foto',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Usa la cámara para detectar la placa',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _procesarImagenPlaca(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.yellow),
                title: const Text('Elegir de galería',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Selecciona una foto existente',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _procesarImagenPlaca(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarImagenPlaca(ImageSource source) async {
    final XFile? imagen = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (imagen == null) return;

    final File imageFile = File(imagen.path);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.yellow),
              const SizedBox(height: 16),
              const Text(
                'Detectando placa...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final placaDetectada = await MotoService.detectarPlacaOCR(imageFile);

      Navigator.pop(context);

      if (placaDetectada != null && placaDetectada.isNotEmpty) {
        setState(() {
          placaController.text = placaDetectada;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(child: Text('Placa detectada: $placaDetectada')),
              ],
            ),
            backgroundColor: Colors.grey[850],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text('No se pudo detectar la placa. Inténtalo de nuevo.'),
                ),
              ],
            ),
            backgroundColor: Colors.grey[850],
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.yellow,
              onPressed: abrirCamaraPlaca,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(child: Text('Error al procesar la imagen')),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> updateMoto() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.yellow),
              const SizedBox(height: 16),
              const Text(
                'Actualizando moto...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    String? uploadedUrl = widget.moto.ruta_imagenMotos;

    if (selectedImage != null) {
      try {
        final url = await MotoService.uploadMotoImage(selectedImage!);
        if (url != null && url.isNotEmpty) {
          uploadedUrl = url;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen actualizada en Supabase'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advertencia: No se actualizó imagen'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    final updatedMoto = Moto(
      id_moto: widget.moto.id_moto,
      placa: placaController.text.trim().toUpperCase(),
      anio: int.tryParse(anioController.text),
      marca: marcaController.text.trim(),
      modelo: modeloController.text.trim(),
      nombreMoto: nombreMotoController.text.trim(),
      tipoMoto: tipoMotoController.text.trim(), // ✅
      kilometraje: int.tryParse(kilometrajeController.text),
      cilindraje: int.tryParse(cilindrajeController.text),
      id_usuario: widget.usuario.idUsuario,
      ruta_imagenMotos: uploadedUrl,
    );

    final result = await MotoService.actualizarMotoAndGet(updatedMoto);

    Navigator.pop(context);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(child: Text('¡Moto actualizada con éxito!')),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(child: Text('Error al actualizar la moto')),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text('Editar Motocicleta',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Imagen de la moto
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[850],
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (widget.moto.ruta_imagenMotos != null &&
                            widget.moto.ruta_imagenMotos!.isNotEmpty)
                            ? NetworkImage(widget.moto.ruta_imagenMotos!)
                        as ImageProvider
                            : null,
                        child: (selectedImage == null &&
                            (widget.moto.ruta_imagenMotos == null ||
                                widget.moto.ruta_imagenMotos!.isEmpty))
                            ? const Icon(Icons.camera_alt,
                            color: Colors.grey, size: 36)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                selectedImage == null
                    ? 'Toca para cambiar la imagen'
                    : 'Imagen seleccionada',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),

              const SizedBox(height: 30),

              _buildTextField('Nombre', controller: nombreMotoController),
              const SizedBox(height: 15),
              _buildTextField('Marca', controller: marcaController),
              const SizedBox(height: 15),
              _buildTextField('Modelo', controller: modeloController),
              const SizedBox(height: 15),

              // ✅ Tipo de moto ahora es campo de texto libre
              _buildTextField('Tipo de Moto', controller: tipoMotoController),
              const SizedBox(height: 15),

              // Campo placa con OCR
              TextFormField(
                controller: placaController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Este campo es obligatorio';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Placa',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ej: ABC-123',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  prefixIcon:
                  const Icon(Icons.credit_card, color: Colors.yellow),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.yellow),
                    onPressed: abrirCamaraPlaca,
                    tooltip: 'Detectar placa con cámara',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.yellow),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.yellow),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    const BorderSide(color: Colors.yellow, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              _buildTextField('Kilometraje',
                  controller: kilometrajeController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField('Año',
                  controller: anioController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField('Cilindraje',
                  controller: cilindrajeController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: updateMoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.save, color: Colors.black, size: 22),
                  label: const Text(
                    'Actualizar Motocicleta',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        required TextEditingController controller,
        TextInputType keyboardType = TextInputType.text,
        bool enabled = true,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (!enabled) return null;
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.yellow, width: 2),
        ),
      ),
    );
  }
}