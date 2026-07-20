import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'EditProfileScreen.dart';
import 'AddMotorcycleScreen.dart';
import 'ViewMotorcycleScreen.dart';
import '../models/usuario.dart';
import '../models/moto.dart';
import '../services/moto_service.dart';
import '../utils/token_manager.dart';
import '../services/auth_service.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  Usuario? usuario;
  List<Moto> motos = [];
  bool isLoading = true;
  int? selectedMotoIndex;
  int? userRole; // Para almacenar el rol del usuario

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final jsonMap = await TokenManager.getUserJson();
    if (jsonMap != null) {
      usuario = Usuario.fromJson(jsonMap);
      motos = await MotoService.listarMotosPorUsuario(usuario!.idUsuario!);

      // Obtener el Rol del Usuario
      userRole = await _obtenerRolUsuario(usuario!.idUsuario!);
    }
    setState(() {
      isLoading = false;
    });
  }

  // Obtener rol del usuario
  Future<int?> _obtenerRolUsuario(int idUsuario) async {
    try {
      // Aquí llamas a tu servicio para obtener los roles
      final roles = await AuthService.obtenerRolesUsuario(idUsuario);

      if (roles != null && roles.isNotEmpty) {
        final rolPrincipal = roles[0] as Map<String, dynamic>;
        return rolPrincipal['idRol'] as int?;
      }
      return null;
    } catch (e) {
      print('Error obteniendo rol: $e');
      return null;
    }
  }

  // Obtener URL según rol
  String _obtenerEnlaceFormulario() {
    if (userRole == 2) {
      // CLIENTE - Formulario de usuarios
      return 'https://forms.gle/z2tH1Vm2dYAv9wNs5';
    } else if (userRole == 3) {
      // MECANICO - Formulario de mecánicos
      return 'https://forms.gle/AQCmxEGBsvGmUjTT8';
    } else if (userRole == 1) {
      // ADMIN - Formulario de administrador
      return 'https://forms.gle/AQCmxEGBsvGmUjTT8';
    } else {
      // Rol desconocido - Sin formulario disponible
      return 'null';
    }
  }

// Obtener texto según rol
  String _obtenerTextoFormulario() {
    if (userRole == 2) {
      return 'Formulario de Satisfacción - Cliente';
    } else if (userRole == 3) {
      return 'Formulario de Satisfacción - Mecánico';
    } else if (userRole == 1) {
      return 'Formulario de Satisfacción - Administrador';
    } else {
      return 'Rol no identificado';
    }
  }

  Widget buildMotoRow(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label1: ',
                  style: const TextStyle(
                    color: Color(0xFFFBC02D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    value1,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label2: ',
                  style: const TextStyle(
                    color: Color(0xFFFBC02D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    value2,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para abrir URL
  Future<void> _launchURL(String url) async {
    try {
      // ignore: deprecated_member_use
      if (await canLaunch(url)) {
        // ignore: deprecated_member_use
        await launch(url);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el formulario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        elevation: 0,
        title: const Text(
          'Mi Perfil',
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
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFBC02D),
        ),
      )
          : usuario == null
          ? const Center(
        child: Text(
          'No se pudo cargar usuario',
          style: TextStyle(color: Colors.white),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con foto y botones
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFBC02D).withOpacity(0.2),
                    const Color(0xFFFBC02D).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFBC02D).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
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
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF2B2B2B),
                          backgroundImage: usuario!.rutaImagen != null &&
                              usuario!.rutaImagen!.isNotEmpty
                              ? NetworkImage(usuario!.rutaImagen!)
                              : null,
                          child: (usuario!.rutaImagen == null ||
                              usuario!.rutaImagen!.isEmpty)
                              ? const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 40,
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nombre y usuario
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario!.nombreCompleto ?? 'Sin nombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${usuario!.nombreUsuario ?? 'usuario'}',
                              style: TextStyle(
                                color: const Color(0xFFFBC02D).withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (usuario != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileScreen(usuario: usuario!),
                                ),
                              );
                              loadUser();
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                          label: const Text(
                            'Editar Perfil',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBC02D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✅ BOTÓN CON ENLACE SEGÚN ROL
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: Text(
                                _obtenerTextoFormulario(),
                                style: const TextStyle(
                                  color: Color(0xFFFBC02D),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'Nos gustaría conocer tu opinión sobre la aplicación. ¿Te gustaría continuar?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    String enlace = _obtenerEnlaceFormulario();

                                    // Validar si el rol tiene formulario disponible
                                    if (enlace == 'null') {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('No hay formulario disponible para tu rol'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(context);
                                    _launchURL(enlace);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFBC02D),
                                  ),
                                  child: const Text(
                                    'Continuar',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2B2B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Color(0xFFFBC02D),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Color(0xFFFBC02D),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Descripción
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBC02D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFFFBC02D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Text(
                usuario!.descripcion?.isNotEmpty == true
                    ? usuario!.descripcion!
                    : 'Aún no has agregado una descripción.',
                style: TextStyle(
                  color: usuario!.descripcion?.isNotEmpty == true
                      ? Colors.white70
                      : Colors.white38,
                  fontSize: 14,
                  fontStyle: usuario!.descripcion?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Garaje virtual
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBC02D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.garage,
                    color: Color(0xFFFBC02D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Garaje Virtual',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de motos
            motos.isEmpty
                ? Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.motorcycle,
                    color: Colors.white.withOpacity(0.3),
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes motos en tu garaje',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Añade tu primera moto!',
                    style: TextStyle(
                      color: Color(0xFFFBC02D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: motos.length,
              itemBuilder: (context, index) {
                final motoItem = motos[index];
                final isSelected = selectedMotoIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedMotoIndex == index) {
                        selectedMotoIndex = null;
                      } else {
                        selectedMotoIndex = index;
                      }
                    });
                  },
                  // Stack con banner lateral
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFBC02D)
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFFFBC02D)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Imagen de la moto
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2B2B),
                                borderRadius: BorderRadius.circular(10),
                                image: motoItem.ruta_imagenMotos != null &&
                                    motoItem.ruta_imagenMotos!.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(
                                      motoItem.ruta_imagenMotos!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: (motoItem.ruta_imagenMotos == null ||
                                  motoItem.ruta_imagenMotos!.isEmpty)
                                  ? Icon(
                                Icons.motorcycle,
                                color: Colors.white.withOpacity(0.3),
                                size: 35,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Info de la moto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${motoItem.marca ?? '-'} ${motoItem.modelo ?? '-'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  buildMotoRow(
                                    'Placa',
                                    motoItem.placa ?? '-',
                                    'Año',
                                    motoItem.anio?.toString() ?? '-',
                                  ),
                                  buildMotoRow(
                                    'Km',
                                    '${motoItem.kilometraje?.toString() ?? '-'} km',
                                    'CC',
                                    '${motoItem.cilindraje?.toString() ?? '-'} cc',
                                  ),
                                ],
                              ),
                            ),
                            // Indicador de selección
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFFBC02D),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                      // Banner con nombre de la Moto
                      if (motoItem.nombreMoto != null &&
                          motoItem.nombreMoto!.isNotEmpty &&
                          motoItem.nombreMoto != 'N/A')
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBC02D),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              motoItem.nombreMoto!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Botón añadir moto
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddMotorcycleScreen(usuario: usuario!),
                    ),
                  ).then((_) => loadUser());
                },
                icon: const Icon(Icons.add, color: Colors.black, size: 22),
                label: const Text(
                  'AÑADIR MI MOTO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBC02D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: selectedMotoIndex != null
          ? FloatingActionButton.extended(
        onPressed: () {
          final selectedMoto = motos[selectedMotoIndex!];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMotorcycleScreen(
                usuario: usuario!,
                moto: selectedMoto,
              ),
            ),
          ).then((updated) {
            if (updated == true) {
              loadUser();
            }
          });
        },
        backgroundColor: const Color(0xFFFBC02D),
        label: const Text(
          'Ver Detalles',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
    );
  }
}