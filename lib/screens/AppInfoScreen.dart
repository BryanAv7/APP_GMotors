import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw 'No se pudo abrir: $url';
    } catch (e) {
      print('Error: $e');
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
          'Información de la App',
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
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ── HERO HEADER ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFBC02D), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBC02D).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logoMotors.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.motorcycle,
                          color: Color(0xFFFBC02D),
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Gorila Motos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBC02D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Versión 1.6.0',
                      style: TextStyle(color: Color(0xFFFBC02D), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ACERCA DE ──
                  _sectionTitle('Acerca de'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: const Text(
                      'GMotos es una plataforma móvil integral diseñada para propietarios de motocicletas, mecánicos y administradores de talleres. '
                          'Optimiza la gestión de mantenimientos, control de inventarios, centraliza la creación de perfiles de usuarios y maximiza la eficiencia operativa de los talleres.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── CARACTERÍSTICAS ──
                  _sectionTitle('Características Principales'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: Column(
                      children: [
                        _featureRow('🏍️', 'Garaje Virtual', 'Control total de tus motocicletas'),
                        _divider(),
                        _featureRow('👁️', 'Escáner con IA', 'Reconocimiento de placas'),
                        _divider(),
                        _featureRow('🧾', 'Facturación Digital', 'Gestión de cobros y presupuestos'),
                        _divider(),
                        _featureRow('📊', 'Historial Clínico', 'Registro detallado de mantenimientos'),
                        _divider(),
                        _featureRow('📦', 'Inventario Inteligente', 'Control de stock y refacciones'),
                        _divider(),
                        _featureRow('🔔', 'Alertas Automáticas', 'Recordatorios de servicios'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── TALLER ──
                  _sectionTitle('Taller de Mecánica'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/taller.jpg',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBC02D).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.build,
                                color: Color(0xFFFBC02D),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gorila Motos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Especialistas en Servicio automotriz',
                                style: TextStyle(
                                  color: Color(0xFFFBC02D),
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Más de 5 años de experiencia en reparación y mantenimiento de motocicletas.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── HORARIOS ──
                  _sectionTitle('Horarios / Ubicación'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: Column(
                      children: [
                        _infoRow(Icons.location_on, 'Camilo Ponce, Cuenca, Ecuador'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time, 'Lunes a Viernes: 8:30 AM - 18:00 PM'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.access_time_outlined, 'Sábados: 9:00 AM - 2:00 PM'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── DESARROLLADORES ──
                  _sectionTitle('Equipo de Desarrollo'),
                  const SizedBox(height: 10),

                  _devCard(
                    nombre: 'Bryan Avila',
                    rol: 'Desarrollador Full Stack',
                    descripcion: 'Responsable del desarrollo integral de la aplicación, incluyendo backend y frontend, gestión de usuarios, integración de IA para reconocimiento de placas y diseño UX.',
                    correo: 'bryan2244ismael@gmail.com',
                    whatsapp: 'https://wa.me/593987329960',
                    fotoAsset: 'assets/images/bryan.jpg',
                  ),

                  const SizedBox(height: 12),

                  _devCard(
                    nombre: 'Paul Paute',
                    rol: 'Desarrollador Full Stack',
                    descripcion: 'Encargado del diseño de la arquitectura de la aplicación, estructura de base de datos, sistema de facturación y gestión de roles de usuario.',
                    correo: 'edwinpau26@hotmail.com',
                    whatsapp: 'https://wa.me/593994183558',
                    fotoAsset: 'assets/images/paul.jpeg',
                  ),

                  const SizedBox(height: 32),

                  // ── FOOTER ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          color: const Color(0xFFFBC02D).withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '© 2026 GMotors. Todos los derechos reservados.',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de desarrollador ──
  Widget _devCard({
    required String nombre,
    required String rol,
    required String descripcion,
    required String correo,
    required String whatsapp,
    String? fotoAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFBC02D).withOpacity(0.2),
                backgroundImage: fotoAsset != null ? AssetImage(fotoAsset) : null,
                child: fotoAsset == null
                    ? Text(
                  nombre[0],
                  style: const TextStyle(
                    color: Color(0xFFFBC02D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      rol,
                      style: const TextStyle(
                        color: Color(0xFFFBC02D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchURL('mailto:$correo'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBC02D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFBC02D).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: Color(0xFFFBC02D), size: 16),
                        SizedBox(width: 6),
                        Text('Correo',
                            style: TextStyle(
                                color: Color(0xFFFBC02D), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchURL(whatsapp),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, color: Color(0xFF25D366), size: 16),
                        SizedBox(width: 6),
                        Text('WhatsApp',
                            style: TextStyle(
                                color: Color(0xFF25D366), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFFBC02D),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _featureRow(String emoji, String titulo, String subtitulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(subtitulo,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFBC02D), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(color: Colors.white12, height: 8);

  BoxDecoration _cardDeco() => BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white12),
  );
}