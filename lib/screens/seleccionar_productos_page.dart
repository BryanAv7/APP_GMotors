import 'package:flutter/material.dart';
import '../models/productos.dart';
import '../models/detalle_ui.dart';
import '../services/productos_service.dart';
import '../widgets/detalle_item_card.dart';
import '../widgets/producto_search_item.dart';

class SeleccionarProductosPage extends StatefulWidget {
  final List<DetalleUI> detallesIniciales;

  const SeleccionarProductosPage({
    super.key,
    this.detallesIniciales = const [],
  });

  @override
  State<SeleccionarProductosPage> createState() =>
      _SeleccionarProductosPageState();
}

class _SeleccionarProductosPageState extends State<SeleccionarProductosPage> {
  // ---------------- DATA ----------------
  List<DetalleUI> detallesSeleccionados = [];
  List<Producto> todosLosProductos = [];
  List<Producto> productosFiltrados = [];
  bool cargandoProductos = false;

  // ---------------- CONTROLLERS ----------------
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    detallesSeleccionados = List.from(widget.detallesIniciales);
    _cargarProductos();
    _testServicio();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // ---------------- CARGAR PRODUCTOS ----------------
  Future<void> _cargarProductos() async {
    //print(' Iniciando carga de productos...');
    setState(() => cargandoProductos = true);

    try {
      final productos = await ProductoService.listarProductos();
      //print(' Productos obtenidos: ${productos.length}');

      setState(() {
        todosLosProductos = productos;
        productosFiltrados = productos;
      });

      //print(' Estado actualizado con ${todosLosProductos.length} productos');
    } catch (e) {
      //print(' Error al cargar productos: $e');
      _mostrarError('Error al cargar productos: $e');
    } finally {
      setState(() => cargandoProductos = false);
      //print(' Carga finalizada. cargandoProductos = false');
    }
  }

  //------TEST
  Future<void> _testServicio() async {
    //print('TEST: Verificando servicio de productos...');

    try {
      final productos = await ProductoService.listarProductos();
      //print('TEST: Productos recibidos: ${productos.length}');

      if (productos.isEmpty) {
        print(' TEST: Lista vacía - posibles causas:');
        print('   1. No hay productos en BD');
        print('   2. Token inválido');
        print('   3. URL incorrecta');
        print('   4. Backend no está corriendo');
      } else {
        //print(' TEST: Primer producto: ${productos.first.nombre}');
      }
    } catch (e) {
      print(' TEST ERROR: $e');
    }
  }

  // ---------------- BÚSQUEDA ----------------
  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        productosFiltrados = todosLosProductos;
      } else {
        productosFiltrados = todosLosProductos.where((p) {
          final nombre = p.nombre?.toLowerCase() ?? '';
          final codigo = p.codigoPersonal?.toLowerCase() ?? '';
          final busqueda = query.toLowerCase();
          return nombre.contains(busqueda) || codigo.contains(busqueda);
        }).toList();
      }
    });
  }

  // ---------------- AGREGAR PRODUCTO ----------------
  void _agregarProducto(Producto producto) {
    // Verificar si ya está agregado
    final index = detallesSeleccionados.indexWhere(
          (d) => d.esProducto && d.idProducto == producto.idProducto,
    );

    setState(() {
      if (index != -1) {
        // Ya existe, aumentar cantidad
        detallesSeleccionados[index] = detallesSeleccionados[index]
            .copyWith(cantidad: detallesSeleccionados[index].cantidad + 1);
      } else {
        // Agregar nuevo
        detallesSeleccionados.add(DetalleUI.fromProducto(producto, 1));
      }
    });

    _mostrarSnackbar('${producto.nombre} agregado', Colors.green);
  }

  // ---------------- AGREGAR CONCEPTO MANUAL ----------------
  void _mostrarDialogoConceptoManual() {
    final descripcionCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    final precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text(
          'Agregar Concepto Manual',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Descripción'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Cantidad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Precio Unitario'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              final desc = descripcionCtrl.text.trim();
              final cant = int.tryParse(cantidadCtrl.text) ?? 1;
              final precio = double.tryParse(precioCtrl.text) ?? 0.0;

              if (desc.isEmpty || precio <= 0) {
                _mostrarError('Complete todos los campos correctamente');
                return;
              }

              setState(() {
                detallesSeleccionados.add(
                  DetalleUI.conceptoManual(
                    descripcion: desc,
                    cantidad: cant,
                    precio: precio,
                  ),
                );
              });

              Navigator.pop(ctx);
              _mostrarSnackbar('Concepto agregado', Colors.green);
            },
            child: const Text('Agregar', style: TextStyle(color: Color(0xFFFBC02D))),
          ),
        ],
      ),
    );
  }

  // ---------------- CAMBIAR CANTIDAD ----------------
  void _cambiarCantidad(int index, int nuevaCantidad) {
    setState(() {
      detallesSeleccionados[index] =
          detallesSeleccionados[index].copyWith(cantidad: nuevaCantidad);
    });
  }

  // ---------------- ELIMINAR ----------------
  void _eliminarDetalle(int index) {
    setState(() {
      detallesSeleccionados.removeAt(index);
    });
    _mostrarSnackbar('Eliminado', Colors.orange);
  }

  // ---------------- CALCULAR TOTAL ----------------
  double get totalGeneral {
    return detallesSeleccionados.fold(
      0.0,
          (sum, detalle) => sum + detalle.subtotal,
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seleccionar Productos',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () => Navigator.pop(context, detallesSeleccionados),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con resumen
          _buildHeader(),

          // Lista de detalles seleccionados
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (detallesSeleccionados.isNotEmpty) ...[
                  const Text(
                    'PRODUCTOS AGREGADOS',
                    style: TextStyle(
                      color: Color(0xFFFBC02D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...detallesSeleccionados.asMap().entries.map((entry) {
                    return DetalleItemCard(
                      detalle: entry.value,
                      onDelete: () => _eliminarDetalle(entry.key),
                      onCantidadChanged: (nuevaCant) =>
                          _cambiarCantidad(entry.key, nuevaCant),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Búsqueda de productos
                const Text(
                  'BUSCAR PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFFBC02D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Buscar por nombre o código'),
                  onChanged: _filtrarProductos,
                ),
                const SizedBox(height: 16),

                // Lista de productos
                if (cargandoProductos)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFBC02D)),
                  )
                else if (productosFiltrados.isEmpty)
                  const Center(
                    child: Text(
                      'No hay productos disponibles',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...productosFiltrados.map((producto) {
                    return ProductoSearchItem(
                      producto: producto,
                      onAdd: () => _agregarProducto(producto),
                    );
                  }),
              ],
            ),
          ),

          // Botón agregar concepto manual
          _buildBotonConceptoManual(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        border: Border(
          bottom: BorderSide(color: Colors.yellow.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionados',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${detallesSeleccionados.length} items',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '\$${totalGeneral.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFBC02D),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonConceptoManual() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        border: Border(
          top: BorderSide(color: Colors.yellow.withOpacity(0.3)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFBC02D).withOpacity(0.2),
            foregroundColor: Color(0xFFFBC02D),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFBC02D)),
            ),
          ),
          onPressed: _mostrarDialogoConceptoManual,
          icon: const Icon(Icons.add),
          label: const Text(
            'Agregar Concepto Manual',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFBC02D)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFBC02D), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}