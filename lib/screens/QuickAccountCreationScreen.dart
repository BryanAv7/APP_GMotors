import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/QuickAccount_service.dart';
import '../services/moto_service.dart';

class QuickAccountCreationScreen extends StatefulWidget {
  const QuickAccountCreationScreen({super.key});

  @override
  State<QuickAccountCreationScreen> createState() =>
      _QuickAccountCreationScreenState();
}

class _QuickAccountCreationScreenState
    extends State<QuickAccountCreationScreen> {
  // Controladores de texto
  final TextEditingController nombreCompletoCtrl = TextEditingController();
  final TextEditingController placaCtrl = TextEditingController();

  // Para evitar múltiples envíos
  bool _isLoading = false;

  // Ícono dinámico para la placa
  Widget? _placaSuffix;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicialmente muestra X
    _placaSuffix = const Icon(Icons.close, color: Colors.red);

    // Escuchar cambios en el campo de placa
    placaCtrl.addListener(() {
      _formatearPlaca();
      _validarPlaca();
    });
  }

  @override
  void dispose() {
    placaCtrl.removeListener(_validarPlaca);
    nombreCompletoCtrl.dispose();
    placaCtrl.dispose();
    super.dispose();
  }

  void _validarPlaca() {
    final placa = placaCtrl.text.trim();

    // Validar que tenga al menos 6 caracteres (formato placa típico)
    if (placa.length >= 6) {
      setState(() => _placaSuffix = const Icon(Icons.check_circle, color: Colors.green));
    } else {
      setState(() => _placaSuffix = const Icon(Icons.close, color: Colors.red));
    }
  }

  void _formatearPlaca() {
    String placa = placaCtrl.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '') // Fix
        .toUpperCase();

    // Máximo 6 caracteres
    if (placa.length > 6) {
      placa = placa.substring(0, 6);
    }

    if (placaCtrl.text != placa) {
      placaCtrl.value = placaCtrl.value.copyWith(
        text: placa,
        selection: TextSelection.fromPosition(
          TextPosition(offset: placa.length),
        ),
      );
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
          placaCtrl.text = placaDetectada;
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

  // Función para crear cuenta rápida
  Future<void> _crearCuentaRapida() async {
    if (_isLoading) return;

    // Validar nombre
    final errorNombre = QuickAccountService.validarNombre(nombreCompletoCtrl.text);
    if (errorNombre != null) {
      _showSnack(errorNombre);
      return;
    }

// Validar que placa NO esté vacía
    if (placaCtrl.text.trim().isEmpty) {
      _showSnack('La placa del vehículo es obligatoria');
      return;
    }

    _formatearPlaca();

// Validar placa
    final errorPlaca = QuickAccountService.validarPlaca(placaCtrl.text);
    if (errorPlaca != null) {
      _showSnack(errorPlaca);
      return;
    }

    setState(() => _isLoading = true);

    final response = await QuickAccountService.crearCuentaRapida(
      nombreCompleto: nombreCompletoCtrl.text,
      placa: placaCtrl.text,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      _showSnack("¡Cuenta rápida creada exitosamente!");

      // Mostrar detalles de la cuenta
      _mostrarDetallesCuenta(
        response.usuarioId,
        response.nombre,
        response.email,
        response.nombreUsuario,
        response.placa,
        response.contrasena,
      );

      // Limpiar campos después de 1 segundo
      Future.delayed(const Duration(seconds: 1), () {
        nombreCompletoCtrl.clear();
        placaCtrl.clear();
      });
    } else {
      _showSnack('Error: ${response.error}');
    }
  }

  void _mostrarDetallesCuenta(
      int? usuarioId,
      String? nombre,
      String? email,
      String? nombreUsuario,
      String? placa,
      String? contrasena,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cuenta Creada',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (email != null) _buildDetailRow('Email:', email),
              const SizedBox(height: 12),
              if (contrasena != null) _buildDetailRow('Contraseña:', contrasena),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[700]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow[700]!),
                ),
                child: const Text(
                  '⚠️ Guarda estos datos temporales. El usuario DEBE cambiar la contraseña cuando solicite su cuenta.',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.yellow[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: const Text(
          'Crear Cuenta Rápida',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Nombre Completo
              _buildField(nombreCompletoCtrl, "Nombre del Usuario"),
              const SizedBox(height: 20),

              // Placa con OCR
              TextField(
                controller: placaCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  label: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Placa del Vehículo',
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.yellow),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.yellow),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.yellow, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Botón Crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearCuentaRapida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Datos por defecto
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[400]!),
                ),
                child: const Text(
                  '💡 Se genera automáticamente los siguientes campos:\n'
                      '• Email: user[nombreUsuario]@gmotors.com\n'
                      '• Contraseña: root111\n'
                      '• Rol: Cliente',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl,
      String hint, {
        bool isPlaca = false,
      }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      textCapitalization: isPlaca ? TextCapitalization.characters : TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: hint,
                style: const TextStyle(color: Colors.grey),
              ),
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 2),
        ),
      ),
    );
  }
}