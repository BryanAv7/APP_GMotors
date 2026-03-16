import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/moto.dart';
import '../models/usuario.dart';
import '../services/moto_service.dart';
import 'package:flutter/services.dart';

class AddMotorcycleScreen extends StatefulWidget {
  final Usuario usuario;

  const AddMotorcycleScreen({super.key, required this.usuario});

  @override
  State<AddMotorcycleScreen> createState() => _AddMotorcycleScreenState();
}

class _AddMotorcycleScreenState extends State<AddMotorcycleScreen> {
  late TextEditingController marcaController;
  late TextEditingController nombreMotoController;
  late TextEditingController modeloController;
  late TextEditingController placaController;
  late TextEditingController kilometrajeController;
  late TextEditingController TipoMotoController;
  late TextEditingController cilindrajeController;
  late TextEditingController anioController;

  File? nuevaImagen;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    marcaController = TextEditingController();
    nombreMotoController = TextEditingController();
    modeloController = TextEditingController();
    placaController = TextEditingController();
    kilometrajeController = TextEditingController();
    TipoMotoController = TextEditingController();
    cilindrajeController = TextEditingController();
    anioController = TextEditingController();
  }

  @override
  void dispose() {
    marcaController.dispose();
    nombreMotoController.dispose();
    modeloController.dispose();
    placaController.dispose();
    kilometrajeController.dispose();
    TipoMotoController.dispose();
    cilindrajeController.dispose();
    anioController.dispose();
    super.dispose();
  }

  // Seleccionar imagen principal de la moto
  Future<void> seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() => nuevaImagen = File(imagen.path));
    }
  }

  // Detectar placa con OCR
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

    // Loader con mensaje mejorado
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

      Navigator.pop(context); // cerrar loader

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
                Expanded(
                  child: Text('Placa detectada: $placaDetectada'),
                ),
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
      Navigator.pop(context); // cerrar loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text('Error al procesar la imagen'),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveMoto() async {
    if (marcaController.text.isEmpty ||
        modeloController.text.isEmpty ||
        placaController.text.isEmpty ||
        TipoMotoController.text.isEmpty ||
        anioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text('Por favor, completa los campos obligatorios.'),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int? anio, kilometraje, cilindraje;
    try {
      anio = int.parse(anioController.text.trim());
      kilometraje = int.parse(kilometrajeController.text.trim());
      cilindraje = int.parse(
        RegExp(r'\d+')
            .stringMatch(cilindrajeController.text.trim()) ??
            '',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text('Año, kilometraje y cilindraje deben ser números válidos.'),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Loader mientras guarda
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
                'Guardando moto...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    String rutaImagen = '';
    if (nuevaImagen != null) {
      try {
        final uploadedImage =
        await MotoService.uploadMotoImage(nuevaImagen!);
        if (uploadedImage != null && uploadedImage.isNotEmpty) {
          rutaImagen = uploadedImage;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida a Supabase'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advertencia: No se subió imagen'),
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

    // nombreMoto predeterminado, envía "N/A"
    final moto = Moto(
      id_moto: null,
      placa: placaController.text.trim().toUpperCase(),
      anio: anio,
      marca: marcaController.text.trim(),
      modelo: modeloController.text.trim(),
      nombreMoto: nombreMotoController.text.trim().isEmpty
          ? 'N/A'
          : nombreMotoController.text.trim(),
      tipoMoto: TipoMotoController.text.trim(),
      kilometraje: kilometraje,
      cilindraje: cilindraje,
      id_usuario: widget.usuario.idUsuario!,
      ruta_imagenMotos: rutaImagen,
    );

    bool success = await MotoService.crearMoto(moto);

    Navigator.pop(context); // cerrar loader

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text('¡Moto registrada con éxito!'),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, moto);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text('Error al registrar la moto. Inténtalo de nuevo.'),
              ),
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
        title: const Text(
          'Añadir Vehículo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la moto
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: seleccionarImagen,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[850],
                      backgroundImage:
                      nuevaImagen != null ? FileImage(nuevaImagen!) : null,
                      child: nuevaImagen == null
                          ? const Icon(Icons.camera_alt,
                          color: Colors.grey, size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Toca la imagen para seleccionar',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campo nombreMoto (Campo Opcional)
            _buildTextField(
              'Nombre',
              controller: nombreMotoController,
              hint: 'Ej: La Poderosa',
            ),
            const SizedBox(height: 15),

            _buildTextField('Marca', controller: marcaController, isRequired: true),
            const SizedBox(height: 15),
            _buildTextField('Modelo', controller: modeloController, isRequired: true),
            const SizedBox(height: 15),

            // Campo placa
            TextField(
              controller: placaController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],

              decoration: InputDecoration(
                label: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Placa',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                hintText: 'Ej: ABC123',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                prefixIcon: const Icon(Icons.credit_card, color: Colors.yellow),
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
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 15),
            _buildTextField('Kilometraje',
                controller: kilometrajeController,
                hint: 'Ej: 15000',
                keyboardType: TextInputType.number,
                isRequired: true),
            const SizedBox(height: 15),

            const SizedBox(height: 15),
            _buildTextField('Tipo de Moto',
                controller: TipoMotoController,
                hint: 'Royal Enfield',
                keyboardType: TextInputType.text,
                isRequired: true),
            const SizedBox(height: 15),

            const SizedBox(height: 15),
            _buildTextField('Año',
                controller: anioController,
                hint: 'Ej: 2022',
                keyboardType: TextInputType.number,
                isRequired: true),
            const SizedBox(height: 15),
            _buildTextField('Cilindraje',
                controller: cilindrajeController, hint: 'Ej: 650',
                isRequired: true),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar',
                    style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        required TextEditingController controller,
        String? hint,
        TextInputType keyboardType = TextInputType.text,
        bool isRequired = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(color: Colors.grey),
              ),
              if (isRequired)  // Campos oblogatorios
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    final isRequired = label.contains('*');
    final cleanLabel = label.replaceAll(' *', '');

    return InputDecorator(
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: cleanLabel,
                style: const TextStyle(color: Colors.grey),
              ),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Selecciona tipo',
              style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: Colors.grey[850],
          items: items
              .map((tipo) =>
              DropdownMenuItem(value: tipo, child: Text(tipo)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}