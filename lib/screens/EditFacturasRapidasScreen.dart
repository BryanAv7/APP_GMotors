import 'package:flutter/material.dart';
import '../models/venta_listado_model.dart';
import '../models/venta_create_model.dart';
import '../models/detalle_venta_createDTO.dart';
import '../models/detalle_ui.dart';
import '../services/venta_service.dart';
import '../utils/token_manager.dart';
import '../screens/seleccionar_productos_page.dart';

class EditFacturasRapidasScreen extends StatefulWidget {
  final VentaListadoModel venta;

  const EditFacturasRapidasScreen({
    super.key,
    required this.venta,
  });

  @override
  State<EditFacturasRapidasScreen> createState() =>
      _EditFacturasRapidasScreenState();
}

class _EditFacturasRapidasScreenState extends State<EditFacturasRapidasScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombreCtrl;
  late TextEditingController cedulaCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController correoCtrl;
  late TextEditingController observacionesCtrl;

  List<DetalleUI> productos = [];

  @override
  void initState() {
    super.initState();

    final v = widget.venta;

    nombreCtrl = TextEditingController(text: v.nombreCliente);
    cedulaCtrl = TextEditingController(text: v.cedulaCliente);
    telefonoCtrl = TextEditingController(text: v.telefonoCliente ?? "");
    direccionCtrl = TextEditingController(text: v.direccionCliente ?? "");
    correoCtrl = TextEditingController(text: v.correoCliente ?? "");
    observacionesCtrl = TextEditingController(text: v.observaciones ?? "");

    productos = v.detalles
        .map((d) => DetalleUI(
      idProducto: d.idProducto,
      nombre: d.descripcion ?? "",
      cantidad: d.cantidad,
      precioUnitario: d.precioUnitario,
      esProducto: true,
    ))
        .toList();
  }

  double get total => productos.fold(0, (s, p) => s + p.subtotal);

  @override
  void dispose() {
    nombreCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    correoCtrl.dispose();
    observacionesCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          "Editar Factura",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle("Información del Cliente", Icons.person),
              const SizedBox(height: 12),
              _clienteFields(),

              const SizedBox(height: 20),

              _buildSectionTitle("Productos y Repuestos", Icons.shopping_cart),
              const SizedBox(height: 12),
              _productosBox(),

              const SizedBox(height: 20),

              _buildSectionTitle("Observaciones", Icons.note),
              const SizedBox(height: 12),
              _observaciones(),

              const SizedBox(height: 30),

              _guardarButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CLIENTE =================

  Widget _clienteFields() {
    return Column(
      children: [
        _input(nombreCtrl, "Nombre Cliente", Icons.person),
        const SizedBox(height: 10),
        _input(cedulaCtrl, "Cédula", Icons.badge),
        const SizedBox(height: 10),
        _input(telefonoCtrl, "Teléfono", Icons.phone),
        const SizedBox(height: 10),
        _input(direccionCtrl, "Dirección", Icons.home),
        const SizedBox(height: 10),
        _input(correoCtrl, "Correo", Icons.email),
      ],
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon) {
    return Container(
      decoration: _boxDecoration(),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        validator: (v) =>
        (v == null || v.isEmpty) ? "Campo obligatorio" : null,
      ),
    );
  }

  // ================= PRODUCTOS =================

  Widget _productosBox() {
    final bool hayProductos = productos.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeleccionarProductosPage(
              detallesIniciales: productos,
            ),
          ),
        );

        if (result != null && result is List<DetalleUI>) {
          setState(() => productos = result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hayProductos
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER estilo PRO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hayProductos ? Icons.check_circle : Icons.edit,
                        color: const Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hayProductos
                          ? "Productos (${productos.length})"
                          : "Editar productos",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              ],
            ),

            // TOTAL estilo tarjeta
            if (hayProductos) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "\$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= OBSERVACIONES =================

  Widget _observaciones() {
    return Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: observacionesCtrl,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ================= BOTÓN =================

  Widget _guardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
        ),
        onPressed: _guardar,
        child: const Text(
          "Actualizar",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ================= LÓGICA =================

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await TokenManager.getUserJson();

    final venta = VentaCreateModel(
      nombre: nombreCtrl.text,
      cedula: cedulaCtrl.text,
      telefono: telefonoCtrl.text,
      direccion: direccionCtrl.text,
      correo: correoCtrl.text,
      idUsuarioVendedor: user?['id_usuario'],
      observaciones: observacionesCtrl.text,
      detalles: productos
          .map((p) => DetalleVentaCreateDTO(
        idProducto: p.idProducto,
        descripcion: p.nombre,
        cantidad: p.cantidad,
        precioUnitario: p.precioUnitario,
      ))
          .toList(),
    );

    final res = await VentaService.actualizarVenta(widget.venta.idVenta, venta);

    if (res != null) {
      Navigator.pop(context, true);
    }
  }

  // ================= STYLE =================

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}