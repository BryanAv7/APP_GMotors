import 'package:flutter/material.dart';
import '../models/registro_dto.dart';
import '../services/registros_service.dart';
import 'AgregarMantenimientoPage.dart';
import 'DetalleMantenimientoPage.dart';

class MantenimientosPage extends StatefulWidget {
  const MantenimientosPage({super.key});

  @override
  State<MantenimientosPage> createState() => _MantenimientosPageState();
}

class _MantenimientosPageState extends State<MantenimientosPage> {
  late Future<List<RegistroDTO>> registrosFuture;
  String _filtroSeleccionado = 'todos';
  bool _ordenReciente = true;
  List<RegistroDTO> _registrosCache = [];
  // Filtro de fecha
  int? _diaFiltro;
  int? _mesFiltro;
  int? _anioFiltro;

  @override
  void initState() {
    super.initState();
    registrosFuture = RegistrosService.listarRegistros();
  }

  void _recargarLista() {
    setState(() {
      registrosFuture = RegistrosService.listarRegistros();
      _registrosCache = [];
    });
  }

  // Convierte el string de fecha a DateTime
  DateTime? _parsearFecha(String fecha) {
    try {
      final partes = fecha.split(',').map((p) => p.trim()).toList();
      if (partes.length == 3) {
        return DateTime(
          int.parse(partes[0]), // año
          int.parse(partes[1]), // mes
          int.parse(partes[2]), // día
        );
      }
    } catch (_) {}

    try {
      return DateTime.parse(fecha); // Formato ISO: 2026-07-25
    } catch (_) {}

    try {
      final partes = fecha.split('/'); // Formato: 25/07/2026
      if (partes.length == 3) {
        return DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      }
    } catch (_) {}

    return null;
  }

  // ================= HELPERS DE ESTADO =================
  Color _colorEstado(int estado) {
    switch (estado) {
      case 0: return Colors.lime;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.deepOrange;
      case 4: return Colors.indigo;
      default: return Colors.white24;
    }
  }

  String _textoEstado(int estado) {
    switch (estado) {
      case 0: return 'Recibido';
      case 1: return 'En Proceso';
      case 2: return 'Finalizado';
      case 3: return 'Entregado';
      case 4: return 'Facturado';
      default: return 'Desconocido';
    }
  }

  IconData _iconoEstado(int estado) {
    switch (estado) {
      case 0: return Icons.inbox;
      case 1: return Icons.pending_actions;
      case 2: return Icons.check_circle;
      case 3: return Icons.local_shipping;
      case 4: return Icons.receipt_long;
      default: return Icons.help_outline;
    }
  }

  // ================= FILTRO =================
  List<RegistroDTO> _aplicarFiltro(List<RegistroDTO> registros) {
    List<RegistroDTO> resultado;

    switch (_filtroSeleccionado) {
      case 'recibido':
        resultado = registros.where((r) => r.estado == 0).toList();
        break;
      case 'enProceso':
        resultado = registros.where((r) => r.estado == 1).toList();
        break;
      case 'finalizado':
        resultado = registros.where((r) => r.estado == 2).toList();
        break;
      case 'entregado':
        resultado = registros.where((r) => r.estado == 3).toList();
        break;
      case 'facturado':
        resultado = registros.where((r) => r.estado == 4).toList();
        break;
      case 'todos':
      default:
        resultado = List.from(registros);
    }

    if (_diaFiltro != null || _mesFiltro != null || _anioFiltro != null) {
      resultado = resultado.where((r) {
        final fecha = _parsearFecha(r.fecha);
        if (fecha == null) return false;
        if (_anioFiltro != null && fecha.year != _anioFiltro) return false;
        if (_mesFiltro != null && fecha.month != _mesFiltro) return false;
        if (_diaFiltro != null && fecha.day != _diaFiltro) return false;
        return true;
      }).toList();
    }

    resultado.sort((a, b) => _ordenReciente
        ? b.fecha.compareTo(a.fecha)
        : a.fecha.compareTo(b.fecha));

    return resultado;
  }

  // ================= MENSAJE VACIO =================
  String _mensajeVacio() {
    switch (_filtroSeleccionado) {
      case 'recibido':   return 'No hay mantenimientos recibidos';
      case 'enProceso':  return 'No hay mantenimientos en proceso';
      case 'finalizado': return 'No hay mantenimientos finalizados';
      case 'entregado':  return 'No hay mantenimientos entregados';
      case 'facturado':  return 'No hay mantenimientos facturados';
      default:           return 'No hay mantenimientos registrados';
    }
  }

  // 🆕 Bottom sheet con 3 selectores: día, mes, año
  void _mostrarFiltroFecha() {
    int? diaTemp = _diaFiltro;
    int? mesTemp = _mesFiltro;
    int? anioTemp = _anioFiltro;

    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final aniosDisponibles = _registrosCache
        .map((r) => _parsearFecha(r.fecha)?.year)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (aniosDisponibles.isEmpty) {
      aniosDisponibles.add(DateTime.now().year);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar por fecha',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Puedes elegir por año-mes-dia, o una fecha exacta',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _buildDropdownFiltro<int>(
                    label: 'Año',
                    value: anioTemp,
                    items: aniosDisponibles,
                    itemLabel: (a) => a.toString(),
                    onChanged: (v) => setModalState(() => anioTemp = v),
                  ),
                  const SizedBox(height: 14),

                  _buildDropdownFiltro<int>(
                    label: 'Mes',
                    value: mesTemp,
                    items: List.generate(12, (i) => i + 1),
                    itemLabel: (m) => meses[m - 1],
                    onChanged: (v) => setModalState(() => mesTemp = v),
                  ),
                  const SizedBox(height: 14),

                  _buildDropdownFiltro<int>(
                    label: 'Día',
                    value: diaTemp,
                    items: List.generate(31, (i) => i + 1),
                    itemLabel: (d) => d.toString(),
                    onChanged: (v) => setModalState(() => diaTemp = v),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              diaTemp = null;
                              mesTemp = null;
                              anioTemp = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _diaFiltro = diaTemp;
                              _mesFiltro = mesTemp;
                              _anioFiltro = anioTemp;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBC02D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🆕 Dropdown reutilizable para el bottom sheet, con opción "Todos"
  Widget _buildDropdownFiltro<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          isExpanded: true,
          value: value,
          dropdownColor: Colors.grey[900],
          hint: Text(label, style: const TextStyle(color: Colors.white54)),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFBC02D)),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text('$label: Todos', style: const TextStyle(color: Colors.white54)),
            ),
            ...items.map(
                  (item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            ),
          ],
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }

  // fecha activa
  Widget _buildChipFiltroFecha() {
    if (_diaFiltro == null && _mesFiltro == null && _anioFiltro == null) {
      return const SizedBox.shrink();
    }

    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    final partes = <String>[];
    if (_diaFiltro != null) partes.add(_diaFiltro.toString().padLeft(2, '0'));
    if (_mesFiltro != null) partes.add(meses[_mesFiltro! - 1]);
    if (_anioFiltro != null) partes.add(_anioFiltro.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: const Icon(Icons.event, size: 16, color: Colors.black),
          label: Text(
            partes.join(' '),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFBC02D),
          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black),
          onDeleted: () {
            setState(() {
              _diaFiltro = null;
              _mesFiltro = null;
              _anioFiltro = null;
            });
          },
        ),
      ),
    );
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
          "Mantenimientos",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: (_diaFiltro != null || _mesFiltro != null || _anioFiltro != null)
                  ? Colors.black
                  : Colors.black54,
            ),
            tooltip: 'Filtrar por Fecha',
            onPressed: _mostrarFiltroFecha,
          ),
          IconButton(
            icon: Icon(
              _ordenReciente ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.black,
            ),
            tooltip: _ordenReciente
                ? 'Más recientes primero'
                : 'Más antiguos primero',
            onPressed: () {
              setState(() => _ordenReciente = !_ordenReciente);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _recargarLista,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<RegistroDTO>>(
        future: registrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando mantenimientos...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Error al cargar datos",
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _recargarLista,
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: const Text('Reintentar',
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          final registros = snapshot.data!;
          _registrosCache = registros;

          //if (registros.isNotEmpty) {
            //debugPrint('FECHA REAL: "${registros.first.fecha}"');
          //}

          return Column(
            children: [
              _buildHeaderStats(registros),
              _buildChipFiltroFecha(),
              Expanded(child: _buildListaMantenimientos(registros)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AgregarMantenimientoPage()),
          );
          if (resultado == true) _recargarLista();
        },
        backgroundColor: const Color(0xFFFBC02D),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Agregar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildListaMantenimientos(List<RegistroDTO> registros) {
    final registrosFiltrados = _aplicarFiltro(registros);

    if (registrosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 80, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              _mensajeVacio(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Presiona el botón + para agregar uno",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: registrosFiltrados.length,
      itemBuilder: (context, index) {
        return _buildCard(context, registrosFiltrados[index], index);
      },
    );
  }

  Widget _buildHeaderStats(List<RegistroDTO> registros) {
    final recibidos   = registros.where((r) => r.estado == 0).length;
    final enProceso   = registros.where((r) => r.estado == 1).length;
    final finalizados = registros.where((r) => r.estado == 2).length;
    final entregados  = registros.where((r) => r.estado == 3).length;
    final facturados  = registros.where((r) => r.estado == 4).length;

    return Container(
      margin: const EdgeInsets.all(10),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItemButton(
              icon: Icons.format_list_bulleted,
              label: 'Total',
              value: '${registros.length}',
              color: const Color(0xFFFFD700),
              filtroKey: 'todos',
            ),
            _buildDivider(),
            _buildStatItemButton(
              icon: Icons.inbox,
              label: 'Recibido',
              value: '$recibidos',
              color: Colors.lime,
              filtroKey: 'recibido',
            ),
            _buildDivider(),
            _buildStatItemButton(
              icon: Icons.pending_actions,
              label: 'Proceso',
              value: '$enProceso',
              color: Colors.blue,
              filtroKey: 'enProceso',
            ),
            _buildDivider(),
            _buildStatItemButton(
              icon: Icons.check_circle,
              label: 'Finalizado',
              value: '$finalizados',
              color: Colors.green,
              filtroKey: 'finalizado',
            ),
            _buildDivider(),
            _buildStatItemButton(
              icon: Icons.motorcycle_outlined,
              label: 'Entregado',
              value: '$entregados',
              color: Colors.deepOrange,
              filtroKey: 'entregado',
            ),
            _buildDivider(),
            _buildStatItemButton(
              icon: Icons.receipt_long,
              label: 'Facturado',
              value: '$facturados',
              color: Colors.indigo,
              filtroKey: 'facturado',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatItemButton({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String filtroKey,
  }) {
    final isSelected = _filtroSeleccionado == filtroKey;

    return GestureDetector(
      onTap: () => setState(() => _filtroSeleccionado = filtroKey),
      child: Column(
        children: [
          if (isSelected)
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 4),
            )
          else
            const SizedBox(height: 7),
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.6),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white54
                  : Colors.white54.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, RegistroDTO registro, int index) {
    return Hero(
      tag: 'registro_${registro.idRegistro}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _colorEstado(registro.estado).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleMantenimientoPage(
                    idRegistro: registro.idRegistro,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen con badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[800],
                          child: registro.rutaImagenMoto.isNotEmpty
                              ? Image.network(
                            registro.rutaImagenMoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.motorcycle,
                              size: 50,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          )
                              : Icon(
                            Icons.motorcycle,
                            size: 50,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${(index + 1).toString().padLeft(3, '0')}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registro.nombreCliente,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.motorcycle,
                                size: 14, color: Color(0xFFFFD700)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${registro.marcaMoto} - ${registro.modeloMoto}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12,
                                color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              registro.fecha,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          registro.descripcion,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge de estado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _colorEstado(registro.estado)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _colorEstado(registro.estado)
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _iconoEstado(registro.estado),
                                    size: 14,
                                    color: _colorEstado(registro.estado),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _textoEstado(registro.estado),
                                    style: TextStyle(
                                      color: _colorEstado(registro.estado),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}