import 'package:flutter/material.dart';
import '../models/ruta.dart';
import '../services/ruta_service.dart';
import '../utils/token_manager.dart';
import 'CrearRutaScreen.dart';
import 'VerRutaScreen.dart';

class MisRutasPage extends StatefulWidget {
  const MisRutasPage({super.key});

  @override
  State<MisRutasPage> createState() => _MisRutasPageState();
}

class _MisRutasPageState extends State<MisRutasPage> {
  List<Ruta> _rutas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRutas();
  }

  Future<void> _cargarRutas() async {
    setState(() => _cargando = true);

    final userMap = await TokenManager.getUserJson();
    if (userMap == null) {
      setState(() => _cargando = false);
      return;
    }

    final idUsuario = userMap['id_usuario'] ?? userMap['idUsuario'];
    final rutas = await RutaService.listarRutasPorUsuario(idUsuario);

    setState(() {
      _rutas = rutas;
      _cargando = false;
    });
  }

  Future<void> _eliminarRuta(Ruta ruta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '¿Eliminar ruta?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "${ruta.nombreRuta}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
            const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await RutaService.eliminarRuta(ruta.idRuta!);
      if (ok) _cargarRutas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title:
        const Text('Mis Rutas', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFFBC02D)),
      )
          : _rutas.isEmpty
          ? _buildEmptyState()
          : _buildListaRutas(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFBC02D),
        icon: const Icon(Icons.add, color: Colors.black),
        label:
        const Text('Nueva Ruta', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearRutaPage()),
          );
          if (res == true) _cargarRutas();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No tienes rutas guardadas',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildListaRutas() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _rutas.length,
      itemBuilder: (_, index) {
        final ruta = _rutas[index];

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.route, color: Color(0xFFFBC02D)),
            title: Text(
              ruta.nombreRuta ?? 'Sin nombre',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${ruta.distanciaKm?.toStringAsFixed(2) ?? 0} km · ${ruta.duracionMinutos ?? 0} min',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            // Ver Detalles Rutas
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerRutaScreen(ruta: ruta),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarRuta(ruta),
            ),
          ),
        );
      },
    );
  }
}