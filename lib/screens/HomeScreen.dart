import 'package:flutter/material.dart';
import 'package:motos_app/screens/HistorialFacturasRapidasScreen.dart';
import 'package:motos_app/screens/VerRutaScreen.dart';
import 'package:motos_app/screens/ViewProfileScreen.dart';
import 'package:motos_app/screens/MantenimientosScreen.dart';
import '../services/auth_service.dart';
import '../utils/token_manager.dart';
import 'dart:convert';
import '../screens/InventarioScreen.dart';
import '../screens/HistorialMantenimientosPage.dart';
import '../screens/RutasMenuScreen.dart';
import '../screens/AppInfoScreen.dart';
import '../screens/QuickAccountCreationScreen.dart';
import '../screens/CrearOfertaScreen.dart';
import '../services/NotificacionService.dart';
import '../screens/VerMisNotificacionesScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedCardIndex = -1;
  String nombreUsuario = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // Inicializar notificaciones FCM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificacionService.inicializar(context);
    });

  }

  // ========================================================
  // Cargar nombre del usuario desde SharedPreferences
  // ========================================================
  Future<void> _loadUserName() async {
    // leer el JSON del usuario guardado
    final userMap = await TokenManager.getUserJson();

    if (userMap != null) {
      setState(() {
        // BACKEND → nombre_usuario
        nombreUsuario = userMap["nombre_usuario"] ??
            userMap["nombreUsuario"] ??
            userMap["nombre_completo"] ??
            "Usuario";
      });
      return;
    }

    // Fallback → intentar extraer del token si algo falla
    final token = await TokenManager.getToken();
    if (token == null) return;

    final parts = token.split(".");
    if (parts.length != 3) return;

    try {
      final payload =
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);

      setState(() {
        nombreUsuario = data["nombre_usuario"] ??
            data["nombreUsuario"] ??
            data["sub"] ??
            "Usuario";
      });
    } catch (e) {
      setState(() => nombreUsuario = "Usuario");
    }
  }

  // Pantallas del bottom navigation
  final List<Widget Function(BuildContext)> _screens = [
        (context) =>
    const Center(child: Text('Inicio', style: TextStyle(color: Colors.white))),
        (context) =>
    const Center(child: Text('Mapa', style: TextStyle(color: Colors.white))),
        (context) =>
    const Center(child: Text('Información', style: TextStyle(color: Colors.white))),
        (context) => const Center(
        child: Text('Notificaciones', style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      // Perfil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ViewProfileScreen()),
      );
    } else if (index == 1) {
      // Mapa
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RutasMenuPage()),
      );
    } else if (index == 2) {
      // Notificaciones
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VerNotificacionesScreen()),
      );
    } else if (index == 3) {
      // INFORMACIÓN
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AppInfoScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,

      // ------------------------------------------------
      // APPBAR
      // ------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text(
          '¡Bienvenido, $nombreUsuario!',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;

              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),

      // ------------------------------------------------
      // BODY
      // ------------------------------------------------
      body: _selectedIndex < 4
          ? Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            // ============== INVENTARIO ==============
            _DashboardCard(
              icon: Icons.inventory,
              label: 'Inventario',
              selected: _selectedCardIndex == 1,
              onTap: () {
                setState(() => _selectedCardIndex = 1);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventarioScreen(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),
/*
            // ============== RESERVAS ==============
            _DashboardCard(
              icon: Icons.notifications,
              label: 'Reservas',
              selected: _selectedCardIndex == 2,
              onTap: () => setState(() => _selectedCardIndex = 2),
            ),
*/
            // ============== MANTENIMIENTOS ==============
            _DashboardCard(
              icon: Icons.motorcycle,
              label: 'Mantenimientos',
              selected: _selectedCardIndex == 3,
              onTap: () {
                setState(() => _selectedCardIndex = 3);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MantenimientosPage(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),

            // ============== HISTORIAL USUARIOS ==============
            _DashboardCard(
              icon: Icons.person,
              label: 'Clientes',
              selected: _selectedCardIndex == 4,
              onTap: () {
                setState(() => _selectedCardIndex = 4);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistorialMantenimientosPage(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),

            // ============== CREAR CUENTAS ==============
            _DashboardCard(
              icon: Icons.person_add,
              label: 'Crear Cuentas',
              selected: _selectedCardIndex == 5,
              onTap: () {
                setState(() => _selectedCardIndex = 5);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuickAccountCreationScreen(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),

            // ============== FACTURAS RAPIDAS ==============
            _DashboardCard(
              icon: Icons.receipt_long,
              label: 'Factura Rapida',
              selected: _selectedCardIndex == 6,
              onTap: () {
                setState(() => _selectedCardIndex = 6);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistorialFacturasRapidasScreen(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),

            // ============== ENVIAR NOTIFICACIONES ==============
            _DashboardCard(
              icon: Icons.notifications,
              label: 'Enviar Notificaciones',
              selected: _selectedCardIndex == 7,
              onTap: () {
                setState(() => _selectedCardIndex = 7);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearOfertaScreen(),
                  ),
                ).then((_) {
                  setState(() => _selectedCardIndex = -1);
                });
              },
            ),

          ],
        ),
      )
          : const SizedBox(),

      // ------------------------------------------------
      // BOTTOM NAVIGATION BAR
      // ------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Color(0xFFFBC02D),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

// --------------------------------------------------------
// TARJETAS DEL DASHBOARD
// --------------------------------------------------------
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.yellow : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}