import 'package:flutter/material.dart';
import '../services/CambiarContrasenaService.dart';
import '../utils/token_manager.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaActualCtrl = TextEditingController();
  final _contrasenaNuevaCtrl = TextEditingController();
  final _confirmarContrasenaCtrl = TextEditingController();

  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirmar = false;
  bool _cargando = false;

  final FocusNode _focusActual = FocusNode();
  final FocusNode _focusNueva = FocusNode();
  final FocusNode _focusConfirmar = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusActual.addListener(_updateFocus);
    _focusNueva.addListener(_updateFocus);
    _focusConfirmar.addListener(_updateFocus);
  }

  void _updateFocus() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusActual.removeListener(_updateFocus);
    _focusNueva.removeListener(_updateFocus);
    _focusConfirmar.removeListener(_updateFocus);
    _contrasenaActualCtrl.dispose();
    _contrasenaNuevaCtrl.dispose();
    _confirmarContrasenaCtrl.dispose();
    _focusActual.dispose();
    _focusNueva.dispose();
    _focusConfirmar.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que las contraseñas coincidan
    if (_contrasenaNuevaCtrl.text.trim() != _confirmarContrasenaCtrl.text.trim()) {
      _mostrarAlertaCentral(
        mensaje: 'Las contraseñas no coinciden',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    // Validar que la nueva sea diferente a la actual
    if (_contrasenaActualCtrl.text.trim() == _contrasenaNuevaCtrl.text.trim()) {
      _mostrarAlertaCentral(
        mensaje: 'La nueva contraseña debe ser diferente',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    // Validar longitud mínima
    if (_contrasenaNuevaCtrl.text.trim().length < 6) {
      _mostrarAlertaCentral(
        mensaje: 'La contraseña debe tener al menos 6 caracteres',
        icono: Icons.warning_amber_outlined,
        color: Colors.orange,
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // Obtener ID del usuario
      final userJson = await TokenManager.getUserJson();
      final idUsuario = userJson?['id_usuario'] ?? 0;

      if (idUsuario == 0) {
        _mostrarAlertaCentral(
          mensaje: 'No se pudo identificar al usuario',
          icono: Icons.error_outline,
          color: Colors.red,
        );
        setState(() => _cargando = false);
        return;
      }

      final resultado = await CambiarContrasenaService.cambiarContrasena(
        idUsuario: idUsuario,
        contrasenaActual: _contrasenaActualCtrl.text.trim(),
        contrasenaNueva: _contrasenaNuevaCtrl.text.trim(),
      );

      if (resultado['success'] == true) {
        _mostrarAlertaCentral(
          mensaje: resultado['mensaje'] ?? 'Contraseña actualizada correctamente',
          icono: Icons.check_circle_outline,
          color: Colors.green,
        );

        _contrasenaActualCtrl.clear();
        _contrasenaNuevaCtrl.clear();
        _confirmarContrasenaCtrl.clear();

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      } else {
        _mostrarAlertaCentral(
          mensaje: resultado['mensaje'] ?? 'Error al cambiar la contraseña',
          icono: Icons.error_outline,
          color: Colors.red,
        );
      }
    } catch (e) {
      _mostrarAlertaCentral(
        mensaje: 'Error: ${e.toString()}',
        icono: Icons.error_outline,
        color: Colors.red,
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // =========================
  // Sistema de alertas central
  // =========================
  OverlayEntry? _overlayEntry;

  void _mostrarAlertaCentral({
    required String mensaje,
    required IconData icono,
    required Color color,
    Duration duracion = const Duration(seconds: 3),
  }) {
    _removerAlerta();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 70,
        left: 40,
        right: 40,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, color: color, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(duracion, _removerAlerta);
  }

  void _removerAlerta() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFBC02D).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFFBC02D), size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ingresa tu contraseña actual y la nueva contraseña que deseas establecer.',
                          style: TextStyle(
                            color: Color(0xFFFBC02D),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contraseña Actual
                _buildCampoContrasena(
                  label: 'Contraseña Actual',
                  controller: _contrasenaActualCtrl,
                  focusNode: _focusActual,
                  obscureText: !_mostrarActual,
                  onVisibilityToggle: () => setState(() => _mostrarActual = !_mostrarActual),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su contraseña actual';
                    }
                    if (value.length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Contraseña Nueva
                _buildCampoContrasena(
                  label: 'Contraseña Nueva',
                  controller: _contrasenaNuevaCtrl,
                  focusNode: _focusNueva,
                  obscureText: !_mostrarNueva,
                  onVisibilityToggle: () => setState(() => _mostrarNueva = !_mostrarNueva),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la nueva contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirmar Contraseña Nueva
                _buildCampoContrasena(
                  label: 'Confirmar Contraseña Nueva',
                  controller: _confirmarContrasenaCtrl,
                  focusNode: _focusConfirmar,
                  obscureText: !_mostrarConfirmar,
                  onVisibilityToggle: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme la nueva contraseña';
                    }
                    if (value != _contrasenaNuevaCtrl.text.trim()) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón Cambiar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _cambiarContrasena,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBC02D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _cargando
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : const Text(
                      'Cambiar Contraseña',
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
      ),
    );
  }

  Widget _buildCampoContrasena({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    Color borderColor;
    if (focusNode.hasFocus) {
      borderColor = const Color(0xFFFBC02D);
    } else if (controller.text.isNotEmpty) {
      borderColor = const Color(0xFFFBC02D).withOpacity(0.5);
    } else {
      borderColor = const Color(0xFFFBC02D).withOpacity(0.3);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: focusNode.hasFocus ? 2.0 : 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          label: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          prefixIcon: const Icon(Icons.lock, color: Colors.white54),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
            onPressed: onVisibilityToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }
}