import 'package:flutter/material.dart';
import '../services/register_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores de texto
  final TextEditingController nombreCompletoCtrl = TextEditingController();
  final TextEditingController nombreUsuarioCtrl = TextEditingController();
  final TextEditingController correoCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();

  // Para mostrar/ocultar contraseña
  bool _obscurePassword = true;

  // Para evitar múltiples envíos
  bool _isLoading = false;

  // Ícono dinámico para el correo
  Widget? _correoSuffix;

  @override
  void initState() {
    super.initState();
    // Inicialmente muestra X
    _correoSuffix = const Icon(Icons.close, color: Colors.red);

    // Escuchar cambios en el campo de correo
    correoCtrl.addListener(_validarCorreo);
  }

  @override
  void dispose() {
    correoCtrl.removeListener(_validarCorreo);
    super.dispose();
  }

  void _validarCorreo() {
    final email = correoCtrl.text.trim();

    // Verificar si termina con el dominio
    if (email.endsWith('@gmail.com') || email.endsWith('@outlook.com')) {
      setState(() => _correoSuffix = const Icon(Icons.check_circle, color: Colors.green));
    } else {
      setState(() => _correoSuffix = const Icon(Icons.close, color: Colors.red));
    }
  }

  // Función para registrarse
  Future<void> _registrarUsuario() async {
    if (_isLoading) return;

    if (nombreCompletoCtrl.text.isEmpty ||
        nombreUsuarioCtrl.text.isEmpty ||
        correoCtrl.text.isEmpty ||
        contrasenaCtrl.text.isEmpty) {
      _showSnack("Completa todos los campos");
      return;
    }

    setState(() => _isLoading = true);

    final success = await RegisterService.registerUser(
      nombreCompleto: nombreCompletoCtrl.text.trim(),
      nombreUsuario: nombreUsuarioCtrl.text.trim(),
      correo: correoCtrl.text.trim(),
      contrasena: contrasenaCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnack("¡Felicidades, Bienvenido a la Familia!");

      // Espera un momento y regresa al login
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context);
      });
    } else {
      _showSnack("Error al registrar usuario");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Color(0xFFFBC02D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Botón atrás
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logoMotors.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[850],
                                    child: Icon(
                                      Icons.motorcycle,
                                      color: Colors.grey[400],
                                      size: 60,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Título
                        const Text(
                          'Registro de Usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Campos
                        _buildField(nombreCompletoCtrl, "Nombre Completo"),
                        const SizedBox(height: 15),

                        _buildField(nombreUsuarioCtrl, "Nombre Usuario"),
                        const SizedBox(height: 15),

                        _buildField(
                            correoCtrl,
                            "Correo Electrónico",
                            isEmail: true
                        ),
                        const SizedBox(height: 15),

                        // Contraseña
                        TextField(
                          controller: contrasenaCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            hintStyle: const TextStyle(color: Colors.grey),
                            label: RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Contraseña',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextSpan(
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Botón Registrar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registrarUsuario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFBC02D),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text(
                              'REGISTRARSE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Texto: ¿Ya tienes una cuenta?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes una cuenta? ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  color: Color(0xFFFBC02D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // * Campos Obligatorios
  Widget _buildField(TextEditingController ctrl, String hint,
      {bool isEmail = false}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
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
        suffixIcon: isEmail ? _correoSuffix : null,
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
      ),
    );
  }
}