import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/oferta.dart';
import '../services/oferta_service.dart';

class CrearOfertaScreen extends StatefulWidget {
  const CrearOfertaScreen({super.key});

  @override
  State<CrearOfertaScreen> createState() => _CrearOfertaScreenState();
}

class _CrearOfertaScreenState extends State<CrearOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  DateTime? fechaInicio;
  DateTime? fechaFin;
  File? imagenSeleccionada;
  bool _cargando = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  // Seleccionar imagen
  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() => imagenSeleccionada = File(imagen.path));
    }
  }

  // Seleccionar fecha
  Future<DateTime?> _seleccionarFecha(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFBC02D),
            surface: Color(0xFF1E1E1E),
          ),
        ),
        child: child!,
      ),
    );
  }

  // Guardar y enviar notificación
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (fechaInicio == null || fechaFin == null) {
      _snack('Selecciona las fechas de inicio y fin', Colors.red);
      return;
    }

    if (fechaFin!.isBefore(fechaInicio!)) {
      _snack('La fecha de fin debe ser después del inicio', Colors.red);
      return;
    }

    setState(() => _cargando = true);

    try {
      // 1. Subir imagen si hay una
      String? imagenUrl;
      if (imagenSeleccionada != null) {
        _snack('Subiendo imagen...', Colors.blue);
        imagenUrl = await OfertaService.subirImagenOferta(imagenSeleccionada!);
        if (imagenUrl == null) {
          _snack('Error al subir la imagen', Colors.red);
          return;
        }
      }

      // 2. Crear la notificación en el backend
      final oferta = Oferta(
        titulo: tituloCtrl.text.trim(),
        descripcion: descripcionCtrl.text.trim(),
        imagenUrl: imagenUrl,
        fechaInicio: fechaInicio!.toIso8601String().split('T')[0],
        fechaFin: fechaFin!.toIso8601String().split('T')[0],
      );

      final creada = await OfertaService.crearOferta(oferta);

      if (creada == null || creada.idOferta == null) {
        _snack('Error al crear la oferta', Colors.red);
        return;
      }

      // 3. Activar oferta
      final activada = await OfertaService.activarOferta(creada.idOferta!);

      if (activada) {
        _snack('¡Oferta creada y enviada!', Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack('Oferta creada pero falló el envío de notificación', Colors.orange);
      }

    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title: const Text('Crear Notificación',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Imagen
              _sectionTitle('Imagen del Producto/Servicio', Icons.image),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _cargando ? null : _seleccionarImagen,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: imagenSeleccionada != null
                          ? const Color(0xFFFBC02D).withOpacity(0.6)
                          : Colors.white24,
                      width: 1.5,
                    ),
                    image: imagenSeleccionada != null
                        ? DecorationImage(
                      image: FileImage(imagenSeleccionada!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: imagenSeleccionada == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate,
                          color: Color(0xFFFBC02D), size: 48),
                      SizedBox(height: 8),
                      Text('Toca para agregar imagen',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // Información
              _sectionTitle('Detalles de la Notificación', Icons.local_offer),
              const SizedBox(height: 12),

              _input(
                controller: tituloCtrl,
                label: 'Título',
                hint: 'Ej: 15% en los cambios de aceites.',
                icon: Icons.title,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 12),

              // Descripción
              Container(
                decoration: _boxDeco(),
                child: TextFormField(
                  controller: descripcionCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.white54),
                    hintText: 'Información adicional.',
                    hintStyle: TextStyle(color: Colors.white24),
                    prefixIcon: Icon(Icons.description, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'La descripción es obligatoria'
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // Fechas
              _sectionTitle('Vigencia', Icons.date_range),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _fechaBtn(
                      label: 'Fecha Inicio',
                      fecha: fechaInicio,
                      onTap: () async {
                        final f = await _seleccionarFecha(context);
                        if (f != null) setState(() => fechaInicio = f);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fechaBtn(
                      label: 'Fecha Fin',
                      fecha: fechaFin,
                      onTap: () async {
                        final f = await _seleccionarFecha(context);
                        if (f != null) setState(() => fechaFin = f);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              //  Botón guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBC02D),
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _cargando
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Enviar Notificación',
                    style: TextStyle(
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
      ),
    );
  }

  // Widgets helper

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBC02D).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFBC02D)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: _boxDeco(),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _fechaBtn({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fecha != null
                ? const Color(0xFFFBC02D).withOpacity(0.5)
                : Colors.white24,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFFFBC02D), size: 16),
                const SizedBox(width: 6),
                Text(
                  fecha != null
                      ? '${fecha.day.toString().padLeft(2, '0')}/'
                      '${fecha.month.toString().padLeft(2, '0')}/'
                      '${fecha.year}'
                      : 'Seleccionar',
                  style: TextStyle(
                    color: fecha != null ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDeco() => BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white24),
  );
}