import 'package:flutter/material.dart';
import '../services/venta_service.dart';
import '../models/venta_listado_model.dart';
import '../screens/FacturasRapidasScreen.dart';
import '../screens/EditFacturasRapidasScreen.dart';

class HistorialFacturasRapidasScreen extends StatefulWidget {
  const HistorialFacturasRapidasScreen({super.key});

  @override
  State<HistorialFacturasRapidasScreen> createState() =>
      _HistorialFacturasRapidasScreenState();
}

class _HistorialFacturasRapidasScreenState
    extends State<HistorialFacturasRapidasScreen> {
  final TextEditingController filtroCtrl = TextEditingController();

  List<VentaListadoModel> facturas = [];
  List<VentaListadoModel> facturasFiltradas = [];
  bool cargando = false;

  // Filtro de fecha
  int? _diaFiltro;
  int? _mesFiltro;
  int? _anioFiltro;

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  @override
  void dispose() {
    filtroCtrl.dispose();
    super.dispose();
  }

  // ================= PARSEAR FECHA =================
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
      return DateTime.parse(fecha);
    } catch (_) {}

    try {
      final partes = fecha.split('/');
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

  // ================= CARGAR FACTURAS =================
  Future<void> _cargarFacturas({String? filtro}) async {
    setState(() => cargando = true);

    try {
      List<VentaListadoModel> data;

      if (filtro == null || filtro.isEmpty) {
        data = await VentaService.listarVentas();
      } else {
        data = await VentaService.buscarFacturasPorTexto(filtro);
      }

      setState(() {
        facturas = data;
        _aplicarFiltros();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  // ================= APLICAR FILTROS =================
  void _aplicarFiltros() {
    List<VentaListadoModel> resultado = List.from(facturas);

    // Filtro por fecha
    if (_diaFiltro != null || _mesFiltro != null || _anioFiltro != null) {
      resultado = resultado.where((r) {
        final fecha = _parsearFecha(r.fechaEmision.toString());
        if (fecha == null) return false;
        if (_anioFiltro != null && fecha.year != _anioFiltro) return false;
        if (_mesFiltro != null && fecha.month != _mesFiltro) return false;
        if (_diaFiltro != null && fecha.day != _diaFiltro) return false;
        return true;
      }).toList();
    }

    setState(() {
      facturasFiltradas = resultado;
    });
  }

  void _buscar() {
    final texto = filtroCtrl.text.trim();

    if (texto.isEmpty) {
      _cargarFacturas();
    } else {
      _cargarFacturas(filtro: texto);
    }
  }

  void _limpiarFiltro() {
    filtroCtrl.clear();
    _diaFiltro = null;
    _mesFiltro = null;
    _anioFiltro = null;
    _cargarFacturas();
  }

  Future<void> _eliminarFactura(int id) async {
    final ok = await VentaService.eliminarVenta(id);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Factura eliminada")),
      );
      _cargarFacturas();
    }
  }

  // Botones de filtros
  void _mostrarFiltroFecha() {
    int? diaTemp = _diaFiltro;
    int? mesTemp = _mesFiltro;
    int? anioTemp = _anioFiltro;

    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    final aniosDisponibles = facturas
        .map((r) => _parsearFecha(r.fechaEmision.toString())?.year)
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
                  // Título y botón cerrar
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
                    'Selecciona año, mes y día',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Filtros
                  Row(
                    children: [
                      // Dropdown de Año
                      Expanded(
                        child: _buildDropdownFiltroCompacto<int>(
                          label: 'Año',
                          value: anioTemp,
                          items: aniosDisponibles,
                          itemLabel: (a) => a.toString(),
                          onChanged: (v) => setModalState(() => anioTemp = v),
                          width: 70,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dropdown de Mes
                      Expanded(
                        child: _buildDropdownFiltroCompacto<int>(
                          label: 'Mes',
                          value: mesTemp,
                          items: List.generate(12, (i) => i + 1),
                          itemLabel: (m) => meses[m - 1],
                          onChanged: (v) => setModalState(() => mesTemp = v),
                          width: 60,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Dropdown de Día
                      Expanded(
                        child: _buildDropdownFiltroCompacto<int>(
                          label: 'Día',
                          value: diaTemp,
                          items: List.generate(31, (i) => i + 1),
                          itemLabel: (d) => d.toString().padLeft(2, '0'),
                          onChanged: (v) => setModalState(() => diaTemp = v),
                          width: 50,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botones de acción
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                              _aplicarFiltros();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBC02D),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

  // 🆕 Dropdown compacto para el bottom sheet
  Widget _buildDropdownFiltroCompacto<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    double width = 70,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          isExpanded: true,
          value: value,
          dropdownColor: Colors.grey[900],
          hint: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFBC02D), size: 20),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text('Todo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            ...items.map(
                  (item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
          onChanged: (v) => onChanged(v),
          elevation: 8,
        ),
      ),
    );
  }

  // ================= CHIP FILTRO FECHA =================
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              _aplicarFiltros();
            });
          },
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: Navigator.canPop(context)
            ? const BackButton(color: Colors.black)
            : null,
        backgroundColor: const Color(0xFFFBC02D),
        title: const Text(
          "Historial F.Rápidas",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
            onPressed: _limpiarFiltro,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFBC02D),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FacturasRapidasScreen(),
            ),
          );

          if (result == true) {
            _cargarFacturas();
          }
        },
        icon: const Icon(Icons.add, color: Colors.black, size: 18),
        label: const Text(
          "Agregar",
          style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          _buildChipFiltroFecha(),
          Expanded(
            child: cargando
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFBC02D),
              ),
            )
                : (facturasFiltradas.isEmpty && facturas.isNotEmpty)
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay facturas que coincidan con el filtro",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Prueba cambiando los filtros",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
                : facturas.isEmpty
                ? const Center(
              child: Text(
                "No hay facturas registradas",
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: facturasFiltradas.length,
              itemBuilder: (context, index) {
                final f = facturasFiltradas[index];

                return Dismissible(
                  key: Key(f.idVenta.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => _eliminarFactura(f.idVenta),
                  child: _facturaCard(f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: filtroCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Buscar por nombre o cédula",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                ),
                onSubmitted: (_) => _buscar(),
              ),
            ),
            IconButton(
              onPressed: _buscar,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFFFBC02D)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoProducto(String label, String valor, {bool destacado = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: destacado ? const Color(0xFFFBC02D) : Colors.white70,
            fontSize: 13,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _facturaCard(VentaListadoModel f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFBC02D).withOpacity(.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: const Color(0xFFFBC02D),
          collapsedIconColor: const Color(0xFFFBC02D),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.production_quantity_limits_outlined,
                color: Color(0xFFFBC02D),
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Cliente:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.nombreCliente,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          "Cédula:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.cedulaCliente,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          "Fecha:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${f.fechaEmision.day.toString().padLeft(2, '0')}/'
                                '${f.fechaEmision.month.toString().padLeft(2, '0')}/'
                                '${f.fechaEmision.year}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "TOTAL",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                "\$${f.costoTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Color(0xFFFBC02D),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          children: [
            const Divider(color: Colors.white24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: Color(0xFFFBC02D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f.telefonoCliente ?? "-",
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag,
                        size: 16,
                        color: Color(0xFFFBC02D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f.detalles.length.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditFacturasRapidasScreen(
                          venta: f,
                        ),
                      ),
                    );

                    if (result == true) {
                      _cargarFacturas();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFFFBC02D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Editar",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              "Detalles Factura",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "🛒 Productos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.06)),
                  ...List.generate(f.detalles.length, (index) {
                    final d = f.detalles[index];
                    final esUltimo = index == f.detalles.length - 1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.descripcion ?? "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDatoProducto("Cantidad", "${d.cantidad}"),
                                  _buildDatoProducto(
                                    "P. Unitario",
                                    "\$${d.precioUnitario.toStringAsFixed(2)}",
                                  ),
                                  _buildDatoProducto(
                                    "Subtotal",
                                    "\$${d.subtotal.toStringAsFixed(2)}",
                                    destacado: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!esUltimo)
                          Container(height: 1, color: Colors.white.withOpacity(0.06)),
                      ],
                    );
                  }),
                ],
              ),
            ),

            if (f.observaciones != null && f.observaciones!.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Observaciones",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  f.observaciones!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}