import 'package:flutter/material.dart';
import '../models/Tipo.dart';
import '../services/tipo_service.dart';

class SeleccionarTipoScreen extends StatefulWidget {
  const SeleccionarTipoScreen({super.key});

  @override
  State<SeleccionarTipoScreen> createState() => _SeleccionarTipoScreenState();
}

class _SeleccionarTipoScreenState extends State<SeleccionarTipoScreen> {
  final TextEditingController _busquedaCtrl = TextEditingController();

  List<Tipo> _todosLosTipos = [];
  List<Tipo> _tiposFiltrados = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaCtrl.removeListener(_filtrar);
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTipos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final tipos = await TipoService.obtenerTodos();

      // Orden alfabético por nombre
      tipos.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      setState(() {
        _todosLosTipos = tipos;
        _tiposFiltrados = tipos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los tipos de servicio';
        _cargando = false;
      });
    }
  }

  void _filtrar() {
    final query = _busquedaCtrl.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _tiposFiltrados = _todosLosTipos;
      } else {
        _tiposFiltrados = _todosLosTipos
            .where((t) => t.nombre.toLowerCase().contains(query))
            .toList();
      }
    });
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
          "Tipo de Servicio",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          //  Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: TextField(
                controller: _busquedaCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Buscar Servicio por Nombre...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFBC02D)),
                  suffixIcon: _busquedaCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => _busquedaCtrl.clear(),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          //  Contador de resultados
          if (!_cargando && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_tiposFiltrados.length} servicio${_tiposFiltrados.length == 1 ? '' : 's'} sisponible${_tiposFiltrados.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Contenido ──
          Expanded(
            child: _cargando
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBC02D)),
            )
                : _error != null
                ? _buildError()
                : _tiposFiltrados.isEmpty
                ? _buildSinResultados()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tiposFiltrados.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tipo = _tiposFiltrados[index];
                return _buildTipoCard(tipo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoCard(Tipo tipo) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, tipo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.build_circle,
                color: Color(0xFFFBC02D),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (tipo.descripcion != null && tipo.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tipo.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _cargarTipos,
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: const Text('Reintentar', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBC02D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.white.withOpacity(0.3), size: 56),
          const SizedBox(height: 16),
          const Text(
            "No se encontraron servicios",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            "Intenta con otro término de búsqueda",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }
}