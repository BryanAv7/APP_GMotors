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

  bool _loading = false;
  bool _obscurePassword = true;
  bool _discoveringServer = false; // 1️⃣ Flag para discovery
  Widget? _correoSuffix;

  String? _savedIp;

  final ServerDiscoveryService _discoveryService = ServerDiscoveryService(); // 1️⃣ Instancia del servicio

  @override
  void initState() {
    super.initState();
    _correoSuffix = const Icon(Icons.close, color: Colors.red);
    correoController.addListener(_validarCorreo);
    _initializeApp(); // 2️⃣ Inicialización con discovery automático
  }

  @override
  void dispose() {
    correoController.removeListener(_validarCorreo);
    _discoveryService.stopDiscovery(); // Limpiar discovery al salir
    super.dispose();
  }

  // 2️⃣ Discovery automático al iniciar
  Future<void> _initializeApp() async {
    await _loadSavedIp();

    // Si no hay IP guardada, iniciar descubrimiento automático
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

  // 2️⃣ Método para iniciar discovery automático
  void _startAutoDiscovery() {
    if (_discoveringServer) return;

    setState(() => _discoveringServer = true);

    _discoveryService.startDiscovery(
      onServerFound: (ip, port) async {
        final ipPuerto = '$ip:$port';
        await ApiConfig.setServerIp(ipPuerto);
        await _loadSavedIp(); // 6️⃣ Refrescar estado después de guardar

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

    // Timeout de 10 segundos
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

  void _validarCorreo() {
    final email = correoController.text.trim();

    if (email.endsWith('@gmail.com') || email.endsWith('@outlook.com')) {
      setState(() => _correoSuffix = const Icon(Icons.check_circle, color: Colors.green));
    } else {
      setState(() => _correoSuffix = const Icon(Icons.close, color: Colors.red));
    }
  }

  Future<void> _login() async {
    // 4️⃣ Protección: no permitir login durante discovery
    if (_discoveringServer) return;

    final correo = correoController.text.trim();
    final contrasena = contrasenaController.text.trim();

    // Verificar si la IP está configurada
    if (_savedIp == null || _savedIp!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configura la IP del servidor antes de iniciar sesión."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (correo.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Obtener Roles y Redireccionamiento
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
          // CLIENTE
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeUserScreen()),
          );
        } else if (idRol == 3) {
          // MECANICO
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (idRol == 1) {
          // ADMIN
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Rol desconocido
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

  // 3️⃣ Diálogo con discovery manual y guardado manual
  void _showIpDialog() {
    final ipPuerto = _savedIp?.split(':') ?? ['', ''];
    final ipController = TextEditingController(text: ipPuerto[0]);
    final puertoController = TextEditingController(text: ipPuerto.length > 1 ? ipPuerto[1] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          "Configurar Servidor",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo IP
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "XXX.XXX.XX.XXX",
                hintStyle: TextStyle(color: Colors.grey[400]),
                labelText: "Dirección IP",
                labelStyle: const TextStyle(color: Colors.yellow),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.yellow),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.yellow),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Campo Puerto
            TextField(
              controller: puertoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "8080",
                hintStyle: TextStyle(color: Colors.grey[400]),
                labelText: "Puerto",
                labelStyle: const TextStyle(color: Colors.yellow),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.yellow),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.yellow),
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

          // 3️⃣ Botón Guardar Manual
          TextButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              final puerto = puertoController.text.trim();

              if (ip.isNotEmpty && puerto.isNotEmpty) {
                final ipPuertoCompleta = '$ip:$puerto';
                await ApiConfig.setServerIp(ipPuertoCompleta);
                await _loadSavedIp(); // 6️⃣ Refrescar estado

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

          // 3️⃣ Botón Buscar Automáticamente
          TextButton(
            onPressed: _discoveringServer
                ? null
                : () {
              Navigator.pop(context);
              _startAutoDiscovery();
            },
            child: Text(
              "Buscar automáticamente",
              style: TextStyle(
                color: _discoveringServer ? Colors.grey : Colors.yellow,
              ),
            ),
          ),
        ],
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
        toolbarHeight: 60,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.yellow),
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
                    child: Column(
                      children: [
                        const Spacer(),

                        // 5️⃣ Indicador visual "Buscando servidor..."
                        if (_discoveringServer) ...[
                          const CircularProgressIndicator(color: Colors.yellow),
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

                        const SizedBox(height: 20),

                        const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CAMPO CORREO - 4️⃣ Deshabilitado durante discovery
                        TextField(
                          controller: correoController,
                          enabled: !_discoveringServer,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Correo',
                            hintStyle: TextStyle(color: Colors.grey[400]),
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            suffixIcon: _correoSuffix,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // CAMPO CONTRASEÑA - 4️⃣ Deshabilitado durante discovery
                        TextField(
                          controller: contrasenaController,
                          enabled: !_discoveringServer,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            hintStyle: TextStyle(color: Colors.grey[400]),
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[400],
                              ),
                              onPressed: _discoveringServer ? null : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _discoveringServer ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OlvideContrasenaScreen(),
                                ),
                              );
                            },
                            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.red)),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // 4️⃣ BOTÓN LOGIN - Deshabilitado durante discovery
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_loading || _discoveringServer) ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                                : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // BOTÓN REGISTRO
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _discoveringServer ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
/*
                        const SizedBox(height: 20),

                        const Text(
                          'O continúa con:',
                          style: TextStyle(color: Colors.white),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _discoveringServer ? null : () {},
                            icon: Image.asset(
                              'assets/images/logoGoogle.png',
                              height: 24,
                              width: 24,
                            ),
                            label: const Text(
                              'Google',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
*/
                        const Spacer(),
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
}