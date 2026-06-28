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
  bool cargando = false;

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

  Future<void> _cargarFacturas({String? filtro}) async {
    setState(() => cargando = true);

    try {
      List<VentaListadoModel> data;

      if (filtro == null || filtro.isEmpty) {
        data = await VentaService.listarVentas();
      } else {
        final esNumerico = RegExp(r'^[0-9]+$').hasMatch(filtro);

        if (esNumerico) {
          data = await VentaService.historialPorCedula(filtro);
        } else {
          data = await VentaService.historialPorNombre(filtro);
        }
      }

      setState(() {
        facturas = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  void _buscar() {
    _cargarFacturas(filtro: filtroCtrl.text.trim());
  }

  void _limpiarFiltro() {
    filtroCtrl.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          "Historial F.Rápidas",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _limpiarFiltro,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),

      // Agregar
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFD700),
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
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Agregar",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold ),
        ),
      ),

      body: Column(
        children: [
          _buildSearchBox(),

          Expanded(
            child: cargando
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
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
              itemCount: facturas.length,
              itemBuilder: (context, index) {
                final f = facturas[index];

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

  // ================= UI =================

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
              ),
            ),
            IconButton(
              onPressed: _buscar,
              icon: const Icon(Icons.arrow_forward,
                  color: Color(0xFFFFD700)),
            )
          ],
        ),
      ),
    );
  }

  Widget _facturaCard(VentaListadoModel f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(.35),
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
          iconColor: const Color(0xFFFFD700),
          collapsedIconColor: const Color(0xFFFFD700),

          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.production_quantity_limits_outlined,
                color: Color(0xFFFFD700),
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

                    // CÉDULA
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

                    // FECHA
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
                  color: Color(0xFFFFD700),
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
                        color: Color(0xFFFFD700),
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
                        color: Color(0xFFFFD700),
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

                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    splashRadius: 18,
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.black,
                    ),
                    onPressed: () async {
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              "Productos",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),


            const SizedBox(height: 15),
            ...f.detalles.map(
                  (d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        d.descripcion ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "x${d.cantidad}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}