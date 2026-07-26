import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/api.dart';
import 'HomeScreen.dart';
import 'RegisterScreen.dart';
import 'HomeUserScreen.dart';
import '../screens/forgot_password_screen.dart';
import '../services/server_discovery_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  // formulario para validación
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _discoveringServer = false;

  String? _savedIp;

  final ServerDiscoveryService _discoveryService = ServerDiscoveryService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _discoveryService.stopDiscovery();
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadSavedIp();
    if (_savedIp == null || _savedIp!.isEmpty) {
      _startAutoDiscovery();
    }
  }

  Future<void> _loadSavedIp() async {
    final prefs = await ApiConfig.getSavedServerIp();
    if (mounted) {
      setState(() {
        _savedIp = prefs;
      });
    }
  }

  void _startAutoDiscovery() {
    if (_discoveringServer) return;

    setState(() => _discoveringServer = true);

    _discoveryService.startDiscovery(
      onServerFound: (ip, port) async {
        final ipPuerto = '$ip:$port';
        await ApiConfig.setServerIp(ipPuerto);
        await _loadSavedIp();

        if (mounted) {
          setState(() => _discoveringServer = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servidor encontrado: $ipPuerto'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (_discoveringServer) {
        _discoveryService.stopDiscovery();
        if (mounted) {
          setState(() => _discoveringServer = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró servidor. Configúralo manualmente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  // Validadores
  String? _validarCorreoField(String? value) {
    final correo = value?.trim() ?? '';
    if (correo.isEmpty) {
      return 'El correo es requerido';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!emailRegex.hasMatch(correo)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validarContrasenaField(String? value) {
    final pass = value?.trim() ?? '';
    if (pass.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (pass.length < 4) {
      return 'Muy corta (mínimo 4 caracteres)';
    }
    return null;
  }

  Future<void> _login() async {
    if (_discoveringServer) return;

    // Validación visual y valida el formulario
    setState(() => _autoValidate = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_savedIp == null || _savedIp!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configura la IP del servidor antes de iniciar sesión."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final correo = correoController.text.trim();
    final contrasena = contrasenaController.text.trim();

    setState(() => _loading = true);

    final response = await AuthService.login(correo, contrasena);

    setState(() => _loading = false);

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correo o contraseña incorrectos"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _redirigirSegunRol(response.usuario.idUsuario);
  }

  Future<void> _redirigirSegunRol(dynamic idUsuario) async {
    try {
      final userId = idUsuario is int ? idUsuario : int.parse(idUsuario.toString());
      final roles = await AuthService.obtenerRolesUsuario(userId);

      if (!mounted) return;

      if (roles != null && roles.isNotEmpty) {
        final rolPrincipal = roles[0] as Map<String, dynamic>;
        final idRol = rolPrincipal['idRol'] as int?;

        if (idRol == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeUserScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  void _showIpDialog() {
    final ipPuerto = _savedIp?.split(':') ?? ['', ''];
    final ipController = TextEditingController(text: ipPuerto[0]);
    final puertoController = TextEditingController(text: ipPuerto.length > 1 ? ipPuerto[1] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("Configurar Servidor", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "XXX.XXX.XX.XXX",
                hintStyle: TextStyle(color: Colors.grey[400]),
                labelText: "Dirección IP",
                labelStyle: const TextStyle(color: Color(0xFFFBC02D)),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFBC02D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFBC02D)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: puertoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "8080",
                hintStyle: TextStyle(color: Colors.grey[400]),
                labelText: "Puerto",
                labelStyle: const TextStyle(color: Color(0xFFFBC02D)),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFBC02D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFBC02D)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              final puerto = puertoController.text.trim();

              if (ip.isNotEmpty && puerto.isNotEmpty) {
                final ipPuertoCompleta = '$ip:$puerto';
                await ApiConfig.setServerIp(ipPuertoCompleta);
                await _loadSavedIp();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Servidor guardado manualmente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Por favor completa todos los campos"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Guardar manual", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: _discoveringServer
                ? null
                : () {
              Navigator.pop(context);
              _startAutoDiscovery();
            },
            child: Text(
              "Buscar automáticamente",
              style: TextStyle(color: _discoveringServer ? Colors.grey : const Color(0xFFFBC02D)),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Decoración reutilizable para inputs, con soporte de error
  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFBC02D), width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFFFBC02D)),
              onPressed: _showIpDialog,
            ),
          ),
        ],
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
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          const Spacer(),

                          if (_discoveringServer) ...[
                            const CircularProgressIndicator(color: Color(0xFFFBC02D)),
                            const SizedBox(height: 10),
                            const Text(
                              'Buscando servidor en la red local...',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],

                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFBC02D), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFBC02D).withOpacity(0.35),
                                    blurRadius: 16,
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

                          const SizedBox(height: 24),

                          const Text(
                            '¡Bienvenido!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inicia sesión para continuar',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),

                          const SizedBox(height: 28),

                          // Correo con validación
                          TextFormField(
                            controller: correoController,
                            enabled: !_discoveringServer,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validarCorreoField,
                            decoration: _inputDecoration(hint: 'Correo'),
                          ),

                          const SizedBox(height: 15),

                          // Contraseña con validación
                          TextFormField(
                            controller: contrasenaController,
                            enabled: !_discoveringServer,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            validator: _validarContrasenaField,
                            decoration: _inputDecoration(
                              hint: 'Contraseña',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[400],
                                ),
                                onPressed: _discoveringServer
                                    ? null
                                    : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _discoveringServer
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OlvideContrasenaScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // BOTÓN LOGIN
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_loading || _discoveringServer) ? null : _login,
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
                                'Iniciar Sesión',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // BOTÓN REGISTRO
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _discoveringServer
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFBC02D), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Registrarse',
                                style: TextStyle(
                                  color: Color(0xFFFBC02D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),
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
}