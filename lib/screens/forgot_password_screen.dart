import 'package:flutter/material.dart';
import '../services/recuperacion_service.dart';

class OlvideContrasenaScreen extends StatefulWidget {
  const OlvideContrasenaScreen({super.key});

  @override
  State<OlvideContrasenaScreen> createState() => _OlvideContrasenaScreenState();
}

class _OlvideContrasenaScreenState extends State<OlvideContrasenaScreen> {
  final TextEditingController correoController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  bool _loading = false;
  bool _emailEnviado = false;

  @override
  void dispose() {
    correoController.dispose();
    super.dispose();
  }

  // Validador
  String? _validarCorreo(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es requerido';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  Future<void> _solicitarRecuperacion() async {
    setState(() => _autoValidate = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final correo = correoController.text.trim();

    setState(() => _loading = true);
    final resultado = await RecuperacionService.solicitarRecuperacion(correo);
    setState(() => _loading = false);

    if (!mounted) return;

    if (resultado?['exito'] ?? false) {
      setState(() => _emailEnviado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado?['mensaje'] ?? 'Error al procesar la solicitud',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFBC02D),
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
        backgroundColor: const Color(0xFFFBC02D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _emailEnviado ? _buildExitoView() : _buildFormView(),
      ),
    );
  }

  // ================= VISTA: FORMULARIO =================
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),

          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFBC02D).withOpacity(0.12),
              border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.4)),
            ),
            child: const Icon(
              Icons.lock_reset,
              color: Color(0xFFFBC02D),
              size: 44,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 28),

          TextFormField(
            controller: correoController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            validator: _validarCorreo,
            decoration: InputDecoration(
              labelText: 'Correo',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'ejemplo@correo.com',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[850],
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFBC02D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFBC02D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFBC02D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFBC02D), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _solicitarRecuperacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBC02D),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Enviar enlace de recuperación',
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
    );
  }

  // ================= VISTA: ÉXITO =================
  Widget _buildExitoView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.15),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Icon(Icons.mark_email_read, color: Colors.green, size: 46),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Correo Enviado!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Revisa la bandeja de entrada de tu correo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 15),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBC02D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFBC02D), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si no lo encuentras en unos minutos, revisa también tu carpeta de Spam.',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFBC02D), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Volver al inicio de sesión',
                style: TextStyle(
                  color: Color(0xFFFBC02D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}