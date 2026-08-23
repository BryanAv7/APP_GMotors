import 'package:flutter/material.dart';
import '../services/ClaveEliminacionService.dart';

class EditarClaveScreen extends StatefulWidget {
  const EditarClaveScreen({super.key});

  @override
  State<EditarClaveScreen> createState() => _EditarClaveScreenState();
}

class _EditarClaveScreenState extends State<EditarClaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _claveActualCtrl = TextEditingController();
  final _claveNuevaCtrl = TextEditingController();
  final _claveConfirmarCtrl = TextEditingController();

  bool _mostrarClaveActual = false;
  bool _mostrarClaveNueva = false;
  bool _mostrarClaveConfirmar = false;
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
    _claveActualCtrl.dispose();
    _claveNuevaCtrl.dispose();
    _claveConfirmarCtrl.dispose();
    _focusActual.dispose();
    _focusNueva.dispose();
    _focusConfirmar.dispose();
    super.dispose();
  }

  Future<void> _actualizarClave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    await ClaveEliminacionService.actualizarClave(
      context: context,
      claveActual: _claveActualCtrl.text.trim(),
      claveNueva: _claveNuevaCtrl.text.trim(),
      confirmarClave: _claveConfirmarCtrl.text.trim(),
      onSuccess: () {
        // Limpiar campos después de éxito
        _claveActualCtrl.clear();
        _claveNuevaCtrl.clear();
        _claveConfirmarCtrl.clear();
        setState(() => _cargando = false);
        Navigator.pop(context, true);
      },
    );

    setState(() => _cargando = false);
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
                          'Ingrese la contraseña para autorizar la eliminación de facturas de mantenimiento.',
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

                // Clave Actual
                _buildClaveField(
                  label: 'Clave Actual',
                  controller: _claveActualCtrl,
                  focusNode: _focusActual,
                  obscureText: !_mostrarClaveActual,
                  onVisibilityToggle: () => setState(() => _mostrarClaveActual = !_mostrarClaveActual),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la clave actual';
                    }
                    if (value.length < 4) {
                      return 'La clave debe tener al menos 4 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Clave Nueva
                _buildClaveField(
                  label: 'Clave Nueva',
                  controller: _claveNuevaCtrl,
                  focusNode: _focusNueva,
                  obscureText: !_mostrarClaveNueva,
                  onVisibilityToggle: () => setState(() => _mostrarClaveNueva = !_mostrarClaveNueva),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la nueva clave';
                    }
                    if (value.length < 4) {
                      return 'La clave debe tener al menos 4 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirmar Clave Nueva
                _buildClaveField(
                  label: 'Confirmar Clave Nueva',
                  controller: _claveConfirmarCtrl,
                  focusNode: _focusConfirmar,
                  obscureText: !_mostrarClaveConfirmar,
                  onVisibilityToggle: () => setState(() => _mostrarClaveConfirmar = !_mostrarClaveConfirmar),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme la nueva clave';
                    }
                    if (value != _claveNuevaCtrl.text.trim()) {
                      return 'Las claves no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón Actualizar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _actualizarClave,
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
                      'Actualizar Contraseña',
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

  Widget _buildClaveField({
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