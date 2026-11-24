import 'package:flutter/material.dart';
import '../models/oferta.dart';
import '../services/oferta_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VerNotificacionesScreen extends StatefulWidget {
  const VerNotificacionesScreen({super.key});

  @override
  State<VerNotificacionesScreen> createState() => _VerNotificacionesScreenState();
}

class _VerNotificacionesScreenState extends State<VerNotificacionesScreen> {
  List<Oferta> _ofertas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarOfertas();
  }

  Future<void> _cargarOfertas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ofertas = await OfertaService.listarOfertasActivas();
      setState(() {
        _ofertas = ofertas;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar notificaciones';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title: const Text('Ver Mis Notificaciones',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _cargarOfertas,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFBC02D)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarOfertas,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBC02D)),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (_ofertas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, color: Colors.white38, size: 80),
            SizedBox(height: 16),
            Text('No hay notificaciones activas',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFBC02D),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: _cargarOfertas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ofertas.length,
        itemBuilder: (context, index) {
          final oferta = _ofertas[index];
          return _NotificacionCard(
            oferta: oferta,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _DetalleOfertaScreen(oferta: oferta),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tarjeta de notificación ──
class _NotificacionCard extends StatelessWidget {
  final Oferta oferta;
  final VoidCallback onTap;

  const _NotificacionCard({required this.oferta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFBC02D).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: oferta.imagenUrl != null && oferta.imagenUrl!.isNotEmpty
                  ? Image.network(
                oferta.imagenUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagenPlaceholder(),
              )
                  : _imagenPlaceholder(),
            ),

            // ── Contenido ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge activa
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '● ACTIVA',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título
                    Text(
                      oferta.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Descripción
                    Text(
                      oferta.descripcion,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
    /*
                    // Fechas
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFFFBC02D), size: 11),
                        const SizedBox(width: 4),
                        Text(
                          '${oferta.fechaInicio} → ${oferta.fechaFin}',
                          style: const TextStyle(
                            color: Color(0xFFFBC02D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    */
                  ],
                ),
              ),
            ),

            // ── Flecha ──
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios,
                  color: Color(0xFFFBC02D), size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFF2C2C2C),
      child: const Icon(Icons.local_offer,
          color: Color(0xFFFBC02D), size: 32),
    );
  }
}

// ── Pantalla de detalle ──
class _DetalleOfertaScreen extends StatelessWidget {
  final Oferta oferta;

  const _DetalleOfertaScreen({required this.oferta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title: const Text('Detalles Notificaciones',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Imagen principal
            if (oferta.imagenUrl != null && oferta.imagenUrl!.isNotEmpty)
              Image.network(
                oferta.imagenUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: const Color(0xFF1E1E1E),
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.white38, size: 60),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBC02D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFBC02D).withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer,
                            color: Color(0xFFFBC02D), size: 14),
                        SizedBox(width: 6),
                        Text('OFERTA ESPECIAL',
                            style: TextStyle(
                              color: Color(0xFFFBC02D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Título
                  Text(
                    oferta.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    oferta.descripcion,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Vigencia
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VIGENCIA DE LA PROMOCIÓN',
                          style: TextStyle(
                            color: Color(0xFFFBC02D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _fechaItem(
                                'Desde',
                                oferta.fechaInicio,
                                Icons.play_circle_outline,
                                Colors.green,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white12,
                            ),
                            Expanded(
                              child: _fechaItem(
                                'Hasta',
                                oferta.fechaFin,
                                Icons.stop_circle_outlined,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  //Botón WhatsApp
                  GestureDetector(
                    onTap: () async {
                      const telefono = '593980834367';
                      final mensaje = '¡Hola! Vi la oferta "${oferta.titulo}" en la app de GorilaMotos y me interesa. ¿Puedes darme más información?';
                      final url = Uri.parse(
                          'https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}'
                      );

                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Consultar por WhatsApp',
                            style: TextStyle(
                              color: Color(0xFF25D366),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fechaItem(
      String label, String fecha, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              Text(fecha,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}