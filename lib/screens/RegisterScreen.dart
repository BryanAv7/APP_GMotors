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
  final TextEditingController confirmarContrasenaCtrl = TextEditingController();

  // Clave y estado de validación del formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nombreCompletoCtrl.dispose();
    nombreUsuarioCtrl.dispose();
    correoCtrl.dispose();
    contrasenaCtrl.dispose();
    confirmarContrasenaCtrl.dispose();
    super.dispose();
  }

  // Validadores específicos por campo
  String? _validarNombreCompleto(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre completo es requerido';
    if (v.length < 3) return 'Ingresa un nombre válido';
    return null;
  }

  String? _validarNombreUsuario(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre de usuario es requerido';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    if (v.contains(' ')) return 'No se permiten espacios';
    return null;
  }

  String? _validarCorreo(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es requerido';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  String? _validarContrasena(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La contraseña es requerida';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validarConfirmarContrasena(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Confirma tu contraseña';
    if (v != contrasenaCtrl.text.trim()) return 'Las contraseñas no coinciden';
    return null;
  }

  // Función para registrarse
  Future<void> _registrarUsuario() async {
    if (_isLoading) return;

    // Validación visual y valida todos los campos
    setState(() => _autoValidate = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    final success = await RegisterService.registerUser(
      nombreCompleto: nombreCompletoCtrl.text.trim(),
      nombreUsuario: nombreUsuarioCtrl.text.trim(),
      correo: correoCtrl.text.trim(),
      contrasena: contrasenaCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      _showSnack("Error al registrar usuario");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFBC02D),
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
                    // 🆕 Todo envuelto en Form
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
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

                          const SizedBox(height: 2),

                          Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFBC02D),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFBC02D).withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logoMotors.png',
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[850],
                                      child: Icon(
                                        Icons.motorcycle,
                                        color: Colors.grey[400],
                                        size: 55,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Únete a la familia Gorila Motors',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),

                          const SizedBox(height: 22),

                          // Campos
                          _buildField(
                            nombreCompletoCtrl,
                            "Nombre Completo",
                            validator: _validarNombreCompleto,
                          ),
                          const SizedBox(height: 15),

                          _buildField(
                            nombreUsuarioCtrl,
                            "Nombre Usuario",
                            validator: _validarNombreUsuario,
                          ),
                          const SizedBox(height: 15),

                          _buildField(
                            correoCtrl,
                            "Correo Electrónico",
                            keyboardType: TextInputType.emailAddress,
                            validator: _validarCorreo,
                          ),
                          const SizedBox(height: 15),

                          // Contraseña
                          _buildField(
                            contrasenaCtrl,
                            "Contraseña",
                            obscureText: _obscurePassword,
                            validator: _validarContrasena,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 🆕 Confirmar contraseña
                          _buildField(
                            confirmarContrasenaCtrl,
                            "Confirmar Contraseña",
                            obscureText: _obscureConfirmPassword,
                            validator: _validarConfirmarContrasena,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Botón Registrar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registrarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBC02D),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
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

                          const SizedBox(height: 3),

                          // Texto: ¿Ya tienes una cuenta?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Ya tienes una cuenta? ',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
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
              ),
            );
          },
        ),
      ),
    );
  }

  // 🆕 Campo reutilizable con validator y soporte de error visual
  Widget _buildField(
      TextEditingController ctrl,
      String hint, {
        String? Function(String?)? validator,
        Widget? suffixIcon,
        bool obscureText = false,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: hint,
                style: const TextStyle(color: Colors.grey),
              ),
              const TextSpan(
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
        suffixIcon: suffixIcon,
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
        // 🆕 Bordes de error, coherentes con LoginScreen
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
    );
  }
}